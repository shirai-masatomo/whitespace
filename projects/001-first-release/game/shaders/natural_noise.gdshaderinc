// Stable integer lattice: avoids sin/hash precision stripes on large world coordinates.
float natural_hash(vec3 cell) {
 uvec3 p=uvec3(ivec3(cell));
 uint h=(p.x*1664525u)^(p.y*1013904223u)^(p.z*2246822519u);
 h=(h^(h>>16u))*2246822519u;
 h=(h^(h>>13u))*3266489917u;
 return float(h^(h>>16u))/4294967295.0;
}
float natural_noise(vec3 point) {
 vec3 i=floor(point), f=fract(point);
 f=f*f*(3.0-2.0*f);
 return mix(
  mix(mix(natural_hash(i),natural_hash(i+vec3(1,0,0)),f.x),
      mix(natural_hash(i+vec3(0,1,0)),natural_hash(i+vec3(1,1,0)),f.x),f.y),
  mix(mix(natural_hash(i+vec3(0,0,1)),natural_hash(i+vec3(1,0,1)),f.x),
      mix(natural_hash(i+vec3(0,1,1)),natural_hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
