-- GPU-only approximate 2D material response; no depth/normal asset or CPU loop.
return [[
extern vec3 ambientColor;
extern vec3 lightColor;
extern float exposure;
extern vec2 lightDirection;
extern float directionStrength;
extern float lightIntensity;
extern float ambientLevel;
extern float rimStrength;
extern float reliefStrength;
extern vec2 texelSize;
extern float spriteMode;
extern vec4 uvRect;
extern vec2 spriteFlip;
extern float forestMask;
extern vec3 forestAnchor;
extern float sceneExposure;
extern vec3 sceneTint;
extern float sceneDirection;
extern vec4 scenePool;
// Hand placed, continuous masks in original forest-art coordinates.
float oval(vec2 uv, vec2 centre, vec2 radius) {
 vec2 d=(uv-centre)/radius;return 1.0-smoothstep(0.35,1.0,dot(d,d));
}
float luminance(vec3 v) { return dot(v,vec3(0.2126,0.7152,0.0722)); }
vec2 bounded(vec2 p) { return clamp(p,uvRect.xy+texelSize*0.5,uvRect.xy+uvRect.zw-texelSize*0.5); }
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
 vec4 raw=Texel(tex,uv);
 vec4 pixel=raw*color;
 vec2 localUV=(uv-uvRect.xy)/max(uvRect.zw,vec2(0.00001));
 localUV=mix(localUV,vec2(1.0)-localUV,spriteFlip);
 // Anchor light to art UV, independent of window/canvas and draw transforms.
 vec2 point=mix(localUV,forestAnchor.xy,forestAnchor.z);
 vec2 dir=normalize(lightDirection);
 float facing=clamp(dot((point-vec2(0.5))*2.0,dir),-1.0,1.0);
 // Contrast gradients approximate local relief, not physical surface normals.
 vec2 stepUV=max(texelSize,vec2(0.00001));
 // Stable texel-centre samples: scaling/filtering must not oscillate relief.
 vec2 sampleUV=(floor(uv/stepUV)+vec2(0.5))*stepUV;
 vec4 left=Texel(tex,bounded(sampleUV-vec2(stepUV.x,0.0)));
 vec4 right=Texel(tex,bounded(sampleUV+vec2(stepUV.x,0.0)));
 vec4 above=Texel(tex,bounded(sampleUV-vec2(0.0,stepUV.y)));
 vec4 below=Texel(tex,bounded(sampleUV+vec2(0.0,stepUV.y)));
 vec2 gradient=vec2(luminance(left.rgb)-luminance(right.rgb),luminance(above.rgb)-luminance(below.rgb));
 gradient*=mix(vec2(1.0),vec2(-1.0),spriteFlip);
 // Palette edges in small Pokemon sprites are painted detail, not surface normals.
 // Turning those one-texel jumps into normals produces oversized square patches
 // once the native or replacement sprite is enlarged by the battle camera.
 // Keep relief on scenery; shade sprites smoothly by their frame and silhouette.
 float relief=clamp(dot(gradient,dir)*3.0,-1.0,1.0)*reliefStrength*(1.0-spriteMode);
 float shade=min(facing,0.0)*directionStrength*sceneDirection*(1.0+(1.0-ambientLevel)*1.5);
 float highlight=max(facing,0.0)*directionStrength*sceneDirection;
 vec3 ambient=mix(vec3(1.0),ambientColor,0.72);
 vec3 lit=pixel.rgb*ambient*exposure*(1.0+shade+relief*0.28);
 lit+=pixel.rgb*lightColor*highlight*0.65;
 // Cooler ambient bounce in darker regions; sprites retain more native hue.
 float cool=clamp((ambientColor.b-ambientColor.r)*1.5,0.0,1.0);
 float shadowMix=cool*mix(0.38,0.10,spriteMode)*(1.0-max(facing,0.0));
 vec3 bounce=vec3(0.48,0.78,1.30)*luminance(lit);
 lit=mix(lit,bounce,shadowMix);
 // Rim on the current sprite silhouette, using only the current atlas frame.
 vec2 edgeDir=dir*mix(vec2(1.0),vec2(-1.0),spriteFlip);
 float edgeLeft=max(0.0,raw.a-left.a)*max(-edgeDir.x,0.0);
 float edgeRight=max(0.0,raw.a-right.a)*max(edgeDir.x,0.0);
 float edgeTop=max(0.0,raw.a-above.a)*max(-edgeDir.y,0.0);
 float edgeBottom=max(0.0,raw.a-below.a)*max(edgeDir.y,0.0);
 float rim=clamp(edgeLeft+edgeRight+edgeTop+edgeBottom,0.0,1.0)*spriteMode*rimStrength;
 lit+=lightColor*rim*0.45*color.rgb;
 float environmentalExposure=mix(sceneExposure,0.75+sceneExposure*0.25,spriteMode);
 vec3 environmentalTint=mix(sceneTint,vec3(1.0),spriteMode*0.65);
 lit*=environmentalTint*environmentalExposure;
 // Broad static illumination, attached to each scene, never an animated noise.
 float pool=exp(-dot((point-scenePool.xy)/scenePool.z,(point-scenePool.xy)/scenePool.z)*2.0);
 lit+=pixel.rgb*lightColor*pool*scenePool.w*(1.0-spriteMode);
 // Forest clearing: independent canopy occlusion and ground illumination.
 // No noise/time input: stable through animation, resizing and camera cropping.
 float ground=smoothstep(0.49,0.59,point.y);
 float clearing=oval(point,vec2(0.53,0.72),vec2(0.46,0.30));
 float canopy=oval(point,vec2(0.12,0.19),vec2(0.25,0.38))
             +oval(point,vec2(0.80,0.19),vec2(0.30,0.36));
 float localShade=clamp(canopy*0.18,0.0,0.25);
 vec3 forestLit=lit*(1.0-localShade);
 float opening=oval(point,vec2(0.49,0.23),vec2(0.17,0.40));
 float shaft=oval(point,vec2(0.21+0.30*(point.y-0.53),0.60),vec2(0.055,0.29))+oval(point,vec2(0.70+0.30*(point.y-0.53),0.60),vec2(0.075,0.28));
 float lightPatch=clearing*ground*0.30+opening*0.15+shaft*0.18;
 forestLit+=pixel.rgb*lightColor*lightPatch;
 lit=mix(lit,forestLit,forestMask);
 lit=mix(pixel.rgb,lit,lightIntensity);
 lit=lit/(vec3(1.0)+max(lit-vec3(0.90),vec3(0.0))*0.65);
 return vec4(clamp(lit,0.0,1.0),pixel.a);
}
]]
