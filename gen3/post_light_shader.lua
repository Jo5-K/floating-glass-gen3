return [[
extern vec2 lightDirection;
extern vec3 lightColor;
extern float lightTime;
extern float artAspect;
extern float daylightAmount;
extern float lightIntensity;
extern float environmentStyle;
extern float battleSeed;
extern float detailStage;
extern vec4 reflectionArea;
extern vec4 beam0;
extern vec4 beam1;
extern vec4 beam2;
extern vec4 beam3;
extern vec4 blocked0;
extern vec4 blocked1;
extern vec4 blocked2;
extern vec4 blocked3;
// SHARED_BEAM_FUNCTIONS
float hash(float x) { return fract(sin(x*127.1+17.3)*43758.5453); }
// Continuous interpolation between seeded targets: no random change per frame.
float drift(float t,float seed) {
 float k=floor(t);float f=fract(t);f=f*f*(3.0-2.0*f);
 return mix(hash(k+seed),hash(k+1.0+seed),f);
}
float blockedArea(vec2 p,vec4 r) {
 if(r.z<=0.0 || r.w<=0.0) return 0.0;
 vec2 a=smoothstep(r.xy,r.xy+vec2(.012),p);
 vec2 b=1.0-smoothstep(r.xy+r.zw-vec2(.012),r.xy+r.zw,p);
 return a.x*a.y*b.x*b.y;
}
float definedRay(vec2 p,vec4 source,float phase) {
 vec2 incoming=-normalize(lightDirection);
 if(incoming.y<.10 || source.w<=0.0) return 0.0;
 float y=p.y-source.y;
 float travel=y/max(.12,1.0-source.y);
 float centre=source.x+y*incoming.x/incoming.y/max(artAspect,.1);
 float variation=drift(lightTime/13.0,battleSeed+phase);
 centre+=max(travel,0.0)*.002*(drift(lightTime/19.0,battleSeed+phase+11.0)-.5);
 float width=max(.004,source.z*(.055+max(y,0.0)*.25))*(.94+.12*variation);
 float feather=mix(.32,1.0,smoothstep(.30,.85,travel));
 float crossSection=1.0-smoothstep(width*(1.0-feather),width,abs(p.x-centre));
 float fade=(1.0-smoothstep(.30,1.0,travel))*smoothstep(0.0,.025,y);
 return crossSection*fade*source.w*(.70+.30*variation);
}
float pool(vec2 p,vec4 source,float phase) {
 if(source.w<=0.0) return 0.0;
 vec2 d=(p-source.xy)*vec2(1.0,.65);
 float r=max(source.z*.65,.035);
 return (1.0-smoothstep(0.0,r,length(d)))*source.w*(.88+.12*drift(lightTime/17.0,battleSeed+phase));
}
float smallDetail(vec2 p,vec4 source,float phase) {
 if(source.w<=0.0) return 0.0;
 float t=lightTime/(11.0+phase);
 // Tiny peripheral/at-source motes; fixed bounded paths and long fade envelopes.
 float life=fract(t+hash(phase+battleSeed));
 vec2 pos=source.xy+vec2(.015*sin(life*6.283+phase),.035*life);
 vec2 delta=abs(p-pos)*vec2(artAspect,1.0);
 float shape=1.0-smoothstep(.0008,.0025,max(delta.x,delta.y));
 return shape*sin(life*3.14159)*source.w;
}
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
 bool canopy=environmentStyle<1.5;
 bool windowLight=environmentStyle>6.5 && environmentStyle<7.5;
 bool water=environmentStyle>5.5 && environmentStyle<6.5;
 bool closed=environmentStyle>7.5;
 float a=0.0;
 if(detailStage>.5) {
  // Source-bound atmospheric details, behind arenas; never full-screen confetti.
  if(canopy || windowLight || closed) {
   a=(smallDetail(uv,beam0,1.0)+smallDetail(uv,beam1,2.0)+smallDetail(uv,beam2,3.0)+smallDetail(uv,beam3,4.0))*.22;
  }
 } else if(canopy || windowLight) {
  float soft=beamField(uv,beam0,lightDirection,artAspect,lightTime,0.0)+beamField(uv,beam1,lightDirection,artAspect,lightTime,1.7);
  float defined=definedRay(uv,beam0,1.0)+definedRay(uv,beam1,3.0);
  // Existing soft veil retained; the additional defined component dissolves at 30%.
  float occlusion=max(max(blockedArea(uv,blocked0),blockedArea(uv,blocked1)),max(blockedArea(uv,blocked2),blockedArea(uv,blocked3)));
  a=soft*.70+defined*.55*(1.0-occlusion);
 } else if(closed) {
  // Lamps/crystals/screens reflect LOCALLY; never solar shafts through a roof.
  a=(pool(uv,beam0,1.0)+pool(uv,beam1,2.0)+pool(uv,beam2,3.0)+pool(uv,beam3,4.0))*.18;
 } else {
  // Open landscapes receive broad ground light, not forest-shaped rays.
  float ground=smoothstep(.48,.85,uv.y);
  float wide=exp(-pow((uv.x-beam0.x)/max(.30,beam0.z),2.0));
  float strength=.018;
  if(environmentStyle>2.5 && environmentStyle<3.5) strength=.026;
  if(environmentStyle>4.5 && environmentStyle<5.5) strength=.012;
  a=wide*ground*strength;
  if(water) a=.026*blockedArea(uv,reflectionArea)*(.80+.20*sin(uv.x*25.0+lightTime*.18));
 }
 float solar=closed?1.0:daylightAmount;
 a=clamp(a*solar*lightIntensity,0.0,detailStage>.5?.045:.18);
 return vec4(clamp(lightColor,0.0,1.0),a*color.a);
}
]]
