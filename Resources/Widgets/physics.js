/* Original Swingset toy models. No DOM, timers, network, or native privileges. */
(function (root) {
'use strict';
const TAU=Math.PI*2, clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const defaults={
 spinner:{angle:0}, bubbles:{popped:Array(24).fill(false)}, clicker:{clicks:0},
 toggles:{switches:Array(8).fill(false)}, gears:{angle:0},
 abacus:{beads:Array.from({length:4},()=>Array.from({length:6},(_,i)=>140+i*42))},
 magnets:{points:[[235,170],[305,170],[270,230],[340,230],[200,230]]},
 elastic:{point:[300,235]}, zipper:{zip:0.55}, cradle:{angles:Array(5).fill(0)}
};
function clean(value,base){
 if(Array.isArray(base))return base.map((v,i)=>clean(Array.isArray(value)?value[i]:undefined,v));
 if(typeof base==='number')return typeof value==='number'&&Number.isFinite(value)?clamp(value,-10000,10000):base;
 if(typeof base==='boolean')return typeof value==='boolean'?value:base;
 const out={};for(const k of Object.keys(base))out[k]=clean(value&&value[k],base[k]);return out;
}
function create(id,saved){if(!defaults[id])throw Error('Unknown toy');const m={id,state:clean(saved,defaults[id]),velocity:0,depth:0,depthV:0,progress:[],vels:Array.from({length:5},()=>[0,0]),omega:Array(5).fill(0),drag:null,events:[],age:0,target:null,lastDetent:0};m.progress=(m.state.switches||[]).map(Number);if(id==='zipper')m.state.zip=clamp(m.state.zip,0,1);if(id==='clicker')m.state.clicks=Math.round(clamp(m.state.clicks,0,999999));if(id==='cradle')m.state.angles=m.state.angles.map(v=>clamp(v,-1.2,1.2));return m;}
function feedback(m,kind='tick'){if(m.events.length<8)m.events.push(kind);}
function normalizeAngle(a){while(a>Math.PI)a-=TAU;while(a< -Math.PI)a+=TAU;return a;}
function detent(m,value,steps){const n=Math.floor(value*steps);if(n!==m.lastDetent){m.lastDetent=n;feedback(m);}}
function press(m,x,y,time=0){m.age=0;m.drag=null;
 switch(m.id){
 case'spinner':case'gears':if(Math.hypot(x-300,y-210)>170)return false;m.drag={angle:Math.atan2(y-210,x-300),time,moved:false};m.velocity=0;break;
 case'bubbles':{let c=Math.floor((x-96)/68),r=Math.floor((y-76)/68);if(c<0||c>=6||r<0||r>=4)return false;let i=r*6+c;if(!m.state.popped[i]){m.state.popped[i]=true;feedback(m,'pop');}break;}
 case'clicker':if(Math.hypot(x-300,y-203)>108)return false;m.drag={};m.depth=1;feedback(m,'down');break;
 case'toggles':{let c=Math.round((x-132)/112),r=Math.round((y-140)/140);if(c<0||c>=4||r<0||r>1||Math.abs(x-(132+c*112))>42)return false;const i=r*4+c;m.state.switches[i]=!m.state.switches[i];feedback(m,'clack');break;}
 case'abacus':{let r=clamp(Math.round((y-105)/70),0,3),i=0;for(let n=1;n<6;n++)if(Math.abs(x-m.state.beads[r][n])<Math.abs(x-m.state.beads[r][i]))i=n;if(Math.abs(x-m.state.beads[r][i])>35)return false;m.drag={row:r,index:i,edge:false};break;}
 case'magnets':{let i=0;for(let n=1;n<5;n++)if(Math.hypot(x-m.state.points[n][0],y-m.state.points[n][1])<Math.hypot(x-m.state.points[i][0],y-m.state.points[i][1]))i=n;if(Math.hypot(x-m.state.points[i][0],y-m.state.points[i][1])>48)return false;m.drag={index:i};m.vels[i]=[0,0];feedback(m,'down');break;}
 case'elastic':m.drag={};m.velocity=0;m.depthV=0;move(m,x,y,time);break;
 case'zipper':if(Math.abs(x-300)>75)return false;m.drag={};m.target=null;move(m,x,y,time);break;
 case'cradle':{const i=x<300?0:4;m.drag={index:i};m.omega.fill(0);m.state.angles.fill(0);move(m,x,y,time);break;}
 }
 return true;
}
function move(m,x,y,time=0){if(!m.drag)return false;
 switch(m.id){
 case'spinner':case'gears':{const a=Math.atan2(y-210,x-300),d=normalizeAngle(a-m.drag.angle),dt=Math.max(.008,time-m.drag.time);m.state.angle+=d;m.velocity=clamp(d/dt,-40,40);m.drag={angle:a,time,moved:true};detent(m,m.state.angle/TAU,m.id==='gears'?24:12);break;}
 case'abacus':{const{row:r,index:i}=m.drag,beads=m.state.beads[r],a=i?beads[i-1]+41:98,b=i<5?beads[i+1]-41:502;beads[i]=clamp(x,98+i*41,502-(5-i)*41);for(let j=i+1;j<6;j++)beads[j]=Math.max(beads[j],beads[j-1]+41);for(let j=i-1;j>=0;j--)beads[j]=Math.min(beads[j],beads[j+1]-41);const edge=beads[0]<=99||beads[5]>=501;if(edge&&!m.drag.edge)feedback(m,'clack');m.drag.edge=edge;break;}
 case'magnets':m.state.points[m.drag.index]=[clamp(x,64,536),clamp(y,64,356)];break;
 case'elastic':m.state.point=[clamp(x,130,470),clamp(y,90,350)];break;
 case'zipper':m.state.zip=clamp(1-(y-80)/270,0,1);detent(m,m.state.zip,26);break;
 case'cradle':{const i=m.drag.index,rx=i===0?200:400;m.state.angles[i]=clamp(Math.atan2(x-rx,y-80),i===0?-1.2:0,i===0?0:1.2);break;}
 }
 return true;
}
function release(m){if(m.id==='elastic'&&m.drag)feedback(m,'twang');if(m.id==='clicker'&&m.drag){m.state.clicks++;feedback(m,'clack');}if((m.id==='spinner'||m.id==='gears')&&m.drag&&!m.drag.moved)m.velocity=m.id==='spinner'?16:7;m.drag=null;m.age=0;}
function action(m){m.age=0;
 switch(m.id){
 case'spinner':m.velocity=22;break;case'gears':m.velocity=8;break;
 case'bubbles':{const i=m.state.popped.indexOf(false);if(i>=0){m.state.popped[i]=true;feedback(m,'pop');}break;}
 case'clicker':m.depth=1;m.depthV=0;m.state.clicks++;feedback(m,'clack');break;
 case'toggles':{const i=m.state.switches.findIndex(v=>!v);m.state.switches[i<0?0:i]=i>=0;feedback(m,'clack');break;}
 case'abacus':{const r=m._row||0,end=m.state.beads[r][0]<180; m.state.beads[r]=Array.from({length:6},(_,i)=>(end?292:98)+i*41);m._row=(r+1)%4;feedback(m,'clack');break;}
 case'magnets':m.state.points[0]=[110,110];m.vels[0]=[110,60];feedback(m);break;
 case'elastic':m.state.point=[300,345];m.velocity=0;m.depthV=0;feedback(m,'twang');break;
 case'zipper':m.target=m.state.zip>.5?0:1;break;
 case'cradle':m.state.angles.fill(0);m.omega.fill(0);m.state.angles[0]=-.95;break;
 }
}
function tick(m,seconds){const dt=clamp(seconds,0,.04);m.age+=dt;let active=false;
 switch(m.id){
 case'spinner':case'gears':if(!m.drag&&Math.abs(m.velocity)>.025){m.state.angle+=m.velocity*dt;m.velocity*=Math.exp(-dt*(m.id==='spinner'?.38:2.1));detent(m,m.state.angle/TAU,m.id==='spinner'?12:24);active=true;}break;
 case'clicker':if(!m.drag){m.depthV+=(-150*m.depth-16*m.depthV)*dt;m.depth+=m.depthV*dt;if(Math.abs(m.depth)+Math.abs(m.depthV)>.003)active=true;else{m.depth=0;m.depthV=0;}}break;
 case'toggles':for(let i=0;i<8;i++){const t=Number(m.state.switches[i]);m.progress[i]+=(t-m.progress[i])*(1-Math.exp(-dt*24));if(Math.abs(t-m.progress[i])>.002)active=true;else m.progress[i]=t;}break;
 case'magnets':{
 const p=m.state.points,force=Array.from({length:5},()=>[0,0]);
 for(let i=0;i<5;i++)for(let j=i+1;j<5;j++){let dx=p[j][0]-p[i][0],dy=p[j][1]-p[i][1],d=Math.max(1,Math.hypot(dx,dy)),f=clamp((d-54)*(d<54?80:d<170?1.8:.08),-2500,600);force[i][0]+=dx/d*f;force[i][1]+=dy/d*f;force[j][0]-=dx/d*f;force[j][1]-=dy/d*f;}
 for(let i=0;i<5;i++){if(m.drag&&m.drag.index===i)continue;for(let k=0;k<2;k++){m.vels[i][k]=(m.vels[i][k]+force[i][k]*dt)*Math.exp(-dt*7);p[i][k]=clamp(p[i][k]+m.vels[i][k]*dt,64,k===0?536:356);}if(Math.hypot(...m.vels[i])>.6)active=true;}
 if(m.age>8&&!m.drag){m.vels.forEach(v=>v.fill(0));active=false;}break;}
 case'elastic':if(!m.drag){for(let k=0;k<2;k++){const target=k?235:300,v=k?'depthV':'velocity';m[v]+=((target-m.state.point[k])*90-m[v]*9)*dt;m.state.point[k]+=m[v]*dt;if(Math.abs(target-m.state.point[k])+Math.abs(m[v])>.08)active=true;}if(!active)m.state.point=[300,235];}break;
 case'zipper':if(m.target!==null){const d=m.target-m.state.zip;m.state.zip+=d*(1-Math.exp(-dt*8));detent(m,m.state.zip,26);if(Math.abs(d)>.001)active=true;else{m.state.zip=m.target;m.target=null;}}break;
 case'cradle':if(!m.drag){for(const i of[0,4]){let old=m.state.angles[i];m.omega[i]+=(-22*Math.sin(old)-.19*m.omega[i])*dt;m.state.angles[i]+=m.omega[i]*dt;if((i===0&&old<0&&m.state.angles[i]>=0&&m.omega[i]>0)||(i===4&&old>0&&m.state.angles[i]<=0&&m.omega[i]<0)){const j=i===0?4:0;m.omega[j]=m.omega[i]*.993;m.state.angles[j]=i===0?.0001:-.0001;m.omega[i]=0;m.state.angles[i]=0;feedback(m,'metal');}if(Math.abs(m.state.angles[i])+Math.abs(m.omega[i])>.004)active=true;}if(m.age>35){m.state.angles.fill(0);m.omega.fill(0);active=false;}}break;
 }
 return active;
}
function serialize(m){return clean(m.state,defaults[m.id]);}
const api={ids:Object.keys(defaults),create,press,move,release,action,tick,serialize,clamp};
if(typeof module!=='undefined'&&module.exports)module.exports=api;else root.SwingsetPhysics=api;
})(globalThis);
