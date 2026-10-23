-- Shared transmitted-light geometry: scene lighting and post-sprite overlay.
return [[
// Shared centre for surface light, soft veil and defined ray. Identical phase.
float beamCentre(vec2 p,vec4 source,vec2 lightDir,float aspect,float time,float phase) {
 vec2 incoming=-normalize(lightDir);
 return source.x+(p.y-source.y)*incoming.x/incoming.y/max(aspect,.1)+.004*sin(time*.22+phase);
}
float beamField(vec2 p, vec4 source, vec2 lightDir, float aspect, float time, float phase) {
 vec2 incoming=-normalize(lightDir);
 if(incoming.y<0.10 || source.w<=0.0) return 0.0;
 float distanceY=p.y-source.y;
 float centreX=beamCentre(p,source,lightDir,aspect,time,phase);
 float width=max(0.008,source.z*(0.18+max(distanceY,0.0)*0.45));
 float across=1.0-smoothstep(width*0.12,width,abs(p.x-centreX));
 float along=smoothstep(0.0,0.16,distanceY)*(1.0-smoothstep(0.84,1.06,p.y));
 return across*along*source.w*(1.0+0.04*sin(time*0.31+phase));
}
]]
