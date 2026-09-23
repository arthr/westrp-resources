(() => {
  'use strict';
  const config=window.WESTRP_LOADING||{};
  const percentage=document.getElementById('loading-percentage');
  const progress=document.querySelector('.progress');
  const fill=document.getElementById('progress-fill');
  const stageText=document.getElementById('loading-stage');
  const connection=document.getElementById('connection-label');
  const tip=document.querySelector('.tip');
  const tipText=document.getElementById('tip-text');
  const steps=[...document.querySelectorAll('.loading-steps li')];
  const stages=[
    {at:0,label:'Estabelecendo conexão...',status:'CONECTANDO AO OESTE'},
    {at:18,label:'Carregando recursos da cidade...',status:'CONEXÃO ESTABELECIDA'},
    {at:48,label:'Preparando o mundo...',status:'SINCRONIZANDO A FRONTEIRA'},
    {at:76,label:'Organizando sua chegada...',status:'QUASE TUDO PRONTO'},
    {at:98,label:'Bem-vindo ao West RP',status:'ENTRANDO NA CIDADE'}
  ];
  let target=0,visible=0,tipIndex=0;
  document.getElementById('server-name').textContent=config.serverName||'WEST RP';
  const clamp=(value,min,max)=>Math.min(Math.max(value,min),max);
  const currentStage=value=>stages.reduce((current,item)=>value>=item.at?item:current,stages[0]);

  function render(value){
    const rounded=Math.round(value);
    const state=currentStage(rounded);
    const active=Math.min(3,Math.floor(rounded/25));
    percentage.textContent=rounded+'%';
    fill.style.width=value+'%';
    progress.setAttribute('aria-valuenow',String(rounded));
    stageText.textContent=state.label;
    connection.textContent=state.status;
    steps.forEach((step,index)=>{
      step.classList.toggle('is-complete',index<active||rounded===100);
      step.classList.toggle('is-active',index===active&&rounded<100);
    });
  }
  function animate(){
    const distance=target-visible;
    visible=Math.abs(distance)>.01?visible+distance*.075:target;
    render(clamp(visible,0,100));
    requestAnimationFrame(animate);
  }
  function rotateTip(){
    const tips=Array.isArray(config.tips)?config.tips.filter(Boolean):[];
    if(tips.length<2)return;
    tip.classList.add('is-changing');
    setTimeout(()=>{tipIndex=(tipIndex+1)%tips.length;tipText.textContent=tips[tipIndex];tip.classList.remove('is-changing')},260);
  }
  window.addEventListener('message',event=>{
    const data=event.data||{};
    if(data.eventName==='loadProgress'){
      target=clamp((Number(data.loadFraction)||0)*100,0,100);
      return;
    }
    const labels={
      startInitFunction:'Iniciando sistemas da cidade...',
      initFunctionInvoking:'Ativando recursos da fronteira...',
      startDataFileEntries:'Carregando mapas e cenários...',
      performMapLoadFunction:'Preparando o Velho Oeste...'
    };
    if(labels[data.eventName])stageText.textContent=labels[data.eventName];
  });
  function startEmbers(){
    const canvas=document.getElementById('embers'),ctx=canvas.getContext('2d');
    if(!ctx||matchMedia('(prefers-reduced-motion: reduce)').matches)return;
    let particles=[],width=0,height=0;
    const make=(bottom=false)=>({x:width*(.37+Math.random()*.32),y:bottom?height+10:height*(.55+Math.random()*.48),size:.5+Math.random()*1.6,speed:.18+Math.random()*.48,drift:(Math.random()-.5)*.22,alpha:.12+Math.random()*.48});
    function resize(){
      const ratio=Math.min(devicePixelRatio||1,2);width=innerWidth;height=innerHeight;
      canvas.width=width*ratio;canvas.height=height*ratio;canvas.style.width=width+'px';canvas.style.height=height+'px';
      ctx.setTransform(ratio,0,0,ratio,0,0);particles=Array.from({length:Math.max(18,Math.floor(width/70))},()=>make());
    }
    function draw(){
      ctx.clearRect(0,0,width,height);
      particles.forEach(p=>{p.y-=p.speed;p.x+=p.drift;p.alpha*=.998;if(p.y<height*.34||p.alpha<.04)Object.assign(p,make(true));ctx.beginPath();ctx.fillStyle='rgba(255,'+(105+p.size*30)+',48,'+p.alpha+')';ctx.shadowColor='#ff5a20';ctx.shadowBlur=5;ctx.arc(p.x,p.y,p.size,0,Math.PI*2);ctx.fill()});
      requestAnimationFrame(draw);
    }
    addEventListener('resize',resize,{passive:true});resize();draw();
  }
  if(Array.isArray(config.tips)&&config.tips[0])tipText.textContent=config.tips[0];
  setInterval(rotateTip,6000);animate();startEmbers();
})();
