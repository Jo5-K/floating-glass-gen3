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
extern float foliageMode;
extern vec4 uvRect;
extern vec2 spriteFlip;
extern float forestMask;
extern vec4 sceneTransform;
extern float sceneLayoutEnabled;
extern float artAspect;
extern float localMode;
extern vec3 localLightColor;
extern float lightTime;
extern float lightMotion;
extern float daylightAmount;
extern vec4 localLight0;
extern vec4 localLight1;
extern vec4 localLight2;
extern vec4 localLight3;
extern vec4 protectedRegion0;
extern vec4 protectedRegion1;
extern vec4 protectedRegion2;
extern vec4 protectedRegion3;
extern float sceneExposure;
extern vec3 sceneTint;
extern float sceneDirection;
extern vec4 scenePool;
// SHARED_BEAM_FUNCTIONS
// Hand placed, continuous masks in original forest-art coordinates.
float oval(vec2 uv, vec2 centre, vec2 radius) {
 vec2 d=(uv-centre)/radius;return 1.0-smoothstep(0.35,1.0,dot(d,d));
}
float protectedArea(vec2 p,vec4 area) {
 if(area.z<=0.0 || area.w<=0.0) return 0.0;
 return oval(p,area.xy+area.zw*0.5,area.zw*0.65);
}
float sourceField(vec2 p,vec4 source,float phase) {
 // Smooth, small local variation. No random draw-time changes or global flicker.
 float pulse=1.0+lightMotion*sin(lightTime*0.31+phase);
 vec2 centre=source.xy;vec2 radius=vec2(max(source.z,0.01));
 if(localMode>7.5) return oval(p,centre+vec2(0.0,0.10),radius*vec2(1.4,0.65))*source.w*pulse*daylightAmount;
 if(localMode>2.5 && localMode<5.5) {
  float lamp=oval(p,centre,radius*vec2(0.65,0.90));
  float bounce=oval(p,centre+vec2(0.0,0.32),radius*vec2(1.1,0.65));
  return (lamp+bounce*0.65)*source.w*pulse*(localMode>5.5 ? daylightAmount : 1.0);
 }
 if((localMode>1.5 && localMode<2.5) || (localMode>5.5 && localMode<6.5)) {
  float beam=beamField(p,source,lightDirection,artAspect,lightTime,phase);
  vec2 incoming=-normalize(lightDirection);
  float floorX=centre.x+(0.70-centre.y)*incoming.x/max(incoming.y,0.1)/max(artAspect,0.1);
  float groundPatch=oval(p,vec2(floorX,0.70),vec2(source.z*0.95,0.065));
  return (beam*0.85+groundPatch*source.w*pulse*0.55)*daylightAmount;
 }
 return oval(p,centre+vec2(0.0,0.12),radius)*source.w*daylightAmount;
}
float luminance(vec3 v) { return dot(v,vec3(0.2126,0.7152,0.0722)); }
vec2 bounded(vec2 p) { return clamp(p,uvRect.xy+texelSize*0.5,uvRect.xy+uvRect.zw-texelSize*0.5); }
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
 vec4 raw=Texel(tex,uv);
 vec4 pixel=raw*color;
 float materialSprite=max(spriteMode,foliageMode);
 vec2 localUV=(uv-uvRect.xy)/max(uvRect.zw,vec2(0.00001));
 localUV=mix(localUV,vec2(1.0)-localUV,spriteFlip);
 // Anchor light to art UV, independent of window/canvas and draw transforms.
 vec2 point=localUV*sceneTransform.xy+sceneTransform.zw;
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
 float relief=clamp(dot(gradient,dir)*3.0,-1.0,1.0)*reliefStrength*(1.0-materialSprite);
 float shade=min(facing,0.0)*directionStrength*sceneDirection*(1.0+(1.0-ambientLevel)*1.5);
 float highlight=max(facing,0.0)*directionStrength*sceneDirection;
 vec3 ambient=mix(vec3(1.0),ambientColor,0.72);
 vec3 lit=pixel.rgb*ambient*exposure*(1.0+shade+relief*0.28);
 lit+=pixel.rgb*lightColor*highlight*0.65;
 // Cooler ambient bounce in darker regions; sprites retain more native hue.
 float cool=clamp((ambientColor.b-ambientColor.r)*1.5,0.0,1.0);
 float shadowMix=cool*mix(0.38,0.10,materialSprite)*(1.0-max(facing,0.0));
 vec3 bounce=vec3(0.48,0.78,1.30)*luminance(lit);
 lit=mix(lit,bounce,shadowMix);
 // Rim on the current sprite silhouette, using only the current atlas frame.
 vec2 edgeDir=dir*mix(vec2(1.0),vec2(-1.0),spriteFlip);
 float edgeLeft=max(0.0,raw.a-left.a)*max(-edgeDir.x,0.0);
 float edgeRight=max(0.0,raw.a-right.a)*max(edgeDir.x,0.0);
 float edgeTop=max(0.0,raw.a-above.a)*max(-edgeDir.y,0.0);
 float edgeBottom=max(0.0,raw.a-below.a)*max(edgeDir.y,0.0);
 float rim=clamp(edgeLeft+edgeRight+edgeTop+edgeBottom,0.0,1.0)*materialSprite*rimStrength;
 lit+=lightColor*rim*mix(0.45,0.22,foliageMode)*color.rgb;
 float environmentalExposure=mix(sceneExposure,0.75+sceneExposure*0.25,materialSprite);
 vec3 environmentalTint=mix(sceneTint,vec3(1.0),materialSprite*0.65);
 lit*=environmentalTint*environmentalExposure;
 // Broad static illumination, attached to each scene, never an animated noise.
 float pool=exp(-dot((point-scenePool.xy)/scenePool.z,(point-scenePool.xy)/scenePool.z)*2.0);
 lit+=pixel.rgb*lightColor*pool*scenePool.w*(1.0-spriteMode);
 // A single art-space field is shared by the backdrop and every arena pixel.
 if(sceneLayoutEnabled>0.5) {
 float forestFill=forestMask*oval(point,vec2(0.53,0.72),vec2(0.46,0.30))*0.08*daylightAmount;
 float coverage=protectedArea(point,protectedRegion0)+protectedArea(point,protectedRegion1)
               +protectedArea(point,protectedRegion2)+protectedArea(point,protectedRegion3);
 float sources=sourceField(point,localLight0,0.0)+sourceField(point,localLight1,1.7)
              +sourceField(point,localLight2,3.1)+sourceField(point,localLight3,4.8);
 // Open plains have broad illumination, not canopy beams or pulsing spotlights.
 if(localMode<1.5) sources=0.0;
 if(localMode>6.5 && localMode<7.5) sources*=0.40;
 float canopyMode=localMode>1.5 && localMode<2.5 ? 1.0 : 0.0;
 vec3 localLit=lit*(1.0-min(coverage,1.0)*mix(0.10,0.22,canopyMode));
 vec3 sourceColor=localMode>2.5 && localMode<5.5 && (localMode<3.5 || localMode>4.5) ? localLightColor : lightColor;
 float direct=min((sources+forestFill)*mix(1.0,1.60,canopyMode),0.65);
 localLit+=pixel.rgb*sourceColor*direct;
 // A restrained transmitted-light veil makes rays visible over dark foliage.
 // It is local, alpha-preserving, and shared by terrain and arena coordinates.
 localLit+=sourceColor*min(sources,0.35)*0.14*canopyMode;
 lit=localLit;
 }
 lit=mix(pixel.rgb,lit,lightIntensity);
 lit=lit/(vec3(1.0)+max(lit-vec3(0.90),vec3(0.0))*0.65);
 return vec4(clamp(lit,0.0,1.0),pixel.a);
}
]]
