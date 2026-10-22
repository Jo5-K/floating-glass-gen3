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
float luminance(vec3 v) { return dot(v,vec3(0.2126,0.7152,0.0722)); }
vec2 bounded(vec2 p) { return clamp(p,uvRect.xy+texelSize*0.5,uvRect.xy+uvRect.zw-texelSize*0.5); }
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
 vec4 raw=Texel(tex,uv);
 vec4 pixel=raw*color;
 vec2 localUV=(uv-uvRect.xy)/max(uvRect.zw,vec2(0.00001));
 localUV=mix(localUV,vec2(1.0)-localUV,spriteFlip);
 vec2 point=mix(screen/love_ScreenSize.xy,localUV,spriteMode);
 vec2 dir=normalize(lightDirection);
 float facing=clamp(dot((point-vec2(0.5))*2.0,dir),-1.0,1.0);
 // Contrast gradients approximate local relief, not physical surface normals.
 vec2 stepUV=max(texelSize,vec2(0.00001));
 vec4 left=Texel(tex,bounded(uv-vec2(stepUV.x,0.0)));
 vec4 right=Texel(tex,bounded(uv+vec2(stepUV.x,0.0)));
 vec4 above=Texel(tex,bounded(uv-vec2(0.0,stepUV.y)));
 vec4 below=Texel(tex,bounded(uv+vec2(0.0,stepUV.y)));
 vec2 gradient=vec2(luminance(left.rgb)-luminance(right.rgb),luminance(above.rgb)-luminance(below.rgb));
 gradient*=mix(vec2(1.0),vec2(-1.0),spriteFlip);
 float relief=clamp(dot(gradient,dir)*3.0,-1.0,1.0)*reliefStrength;
 float shade=min(facing,0.0)*directionStrength*(1.0+(1.0-ambientLevel)*1.5);
 float highlight=max(facing,0.0)*directionStrength;
 vec3 ambient=mix(vec3(1.0),ambientColor,0.72);
 vec3 lit=pixel.rgb*ambient*exposure*(1.0+shade+relief*0.45);
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
 lit=mix(pixel.rgb,lit,lightIntensity);
 lit=lit/(vec3(1.0)+max(lit-vec3(0.90),vec3(0.0))*0.65);
 return vec4(clamp(lit,0.0,1.0),pixel.a);
}
]]
