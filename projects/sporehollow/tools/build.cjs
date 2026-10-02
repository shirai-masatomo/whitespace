const fs=require('node:fs');const path=require('node:path');const root=path.resolve(__dirname,'..');
fs.mkdirSync(path.join(root,'build/src'),{recursive:true});
for(const file of ['index.html','style.css','src/sim.js','src/app.js'])fs.copyFileSync(path.join(root,file),path.join(root,'build',file));
console.log('Standalone offline build: '+path.join(root,'build/index.html'));
