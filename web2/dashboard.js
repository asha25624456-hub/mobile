
(() => {
    const getCanvas = id => document.getElementById(id);
    const dprCanvas = canvas => {
        if (!canvas) return null;
        const rect = canvas.getBoundingClientRect();
        const ratio = window.devicePixelRatio || 1;
        canvas.width = Math.max(1, Math.floor(rect.width * ratio));
        canvas.height = Math.max(1, Math.floor(rect.height * ratio));
        const ctx = canvas.getContext('2d');
        ctx.setTransform(ratio,0,0,ratio,0,0);
        return {ctx,w:rect.width,h:rect.height};
    };
    const clear = (ctx,w,h) => { ctx.clearRect(0,0,w,h); };
    const text = (ctx,s,x,y,size=11,weight='400') => {
        ctx.font = `${weight} ${size}px Tahoma, "Noto Sans Thai", sans-serif`;
        ctx.fillStyle = '#667085'; ctx.fillText(String(s),x,y);
    };

    function lineChart(rows){
        const canvas=getCanvas('monthlyUsageChart'), box=dprCanvas(canvas); if(!box) return;
        const {ctx,w,h}=box; clear(ctx,w,h);
        const left=44,right=16,top=16,bottom=32, cw=w-left-right,ch=h-top-bottom;
        const max=Math.max(1,...rows.map(x=>Number(x.quantity)||0));
        ctx.strokeStyle='#e8ecf3'; ctx.lineWidth=1;
        for(let i=0;i<5;i++){const y=top+ch*i/4;ctx.beginPath();ctx.moveTo(left,y);ctx.lineTo(w-right,y);ctx.stroke();text(ctx,Math.round(max*(1-i/4)).toLocaleString('th-TH'),4,y+4,10);}
        const pts=rows.map((r,i)=>({x:left+(rows.length===1?0:i*(cw/(rows.length-1))),y:top+ch-(Number(r.quantity)||0)/max*ch}));
        if(pts.length>1){ctx.strokeStyle='#315ee8';ctx.lineWidth=3;ctx.beginPath();pts.forEach((p,i)=>i?ctx.lineTo(p.x,p.y):ctx.moveTo(p.x,p.y));ctx.stroke();}
        pts.forEach((p,i)=>{ctx.fillStyle='#fff';ctx.strokeStyle='#315ee8';ctx.lineWidth=2;ctx.beginPath();ctx.arc(p.x,p.y,4,0,Math.PI*2);ctx.fill();ctx.stroke();text(ctx,rows[i].label,p.x-20,h-8,9);});
    }

    function barChart(rows){
        const canvas=getCanvas('topBorrowedChart'), box=dprCanvas(canvas); if(!box) return;
        const {ctx,w,h}=box; clear(ctx,w,h);
        const left=130,right=18,top=15,bottom=24,cw=w-left-right,ch=h-top-bottom;
        const max=Math.max(1,...rows.map(x=>Number(x.quantity)||0));
        const gap=10, barH=Math.max(18,(ch-gap*(rows.length-1))/Math.max(1,rows.length));
        rows.forEach((r,i)=>{
            const y=top+i*(barH+gap), val=Number(r.quantity)||0, bw=val/max*cw;
            text(ctx,r.product_name,left-8,y+barH/2+4,10);
            ctx.fillStyle='#eaf0ff';ctx.fillRect(left,y,cw,barH);
            ctx.fillStyle='#315ee8';ctx.fillRect(left,y,bw,barH);
            text(ctx,val.toLocaleString('th-TH'),Math.min(left+bw+6,w-28),y+barH/2+4,10,'700');
        });
    }

    function donutChart(rows){
        const canvas=getCanvas('requestStatusChart'), box=dprCanvas(canvas); if(!box) return;
        const {ctx,w,h}=box; clear(ctx,w,h);
        const total=rows.reduce((s,r)=>s+(Number(r.value)||0),0);
        if(!total){text(ctx,'ยังไม่มีข้อมูล',w/2-35,h/2,12);return;}
        const cx=w*0.42,cy=h*0.46,r=Math.min(w,h)*.29,inner=r*.58;
        let angle=-Math.PI/2;
        const labels=[];
        rows.forEach((row,i)=>{
            const val=Number(row.value)||0, next=angle+val/total*Math.PI*2;
            ctx.beginPath();ctx.moveTo(cx,cy);ctx.arc(cx,cy,r,angle,next);ctx.closePath();
            ctx.fillStyle=['#315ee8','#6f52c9','#2f9b61','#c83d50'][i%4];ctx.fill();
            labels.push({row,percent:Math.round(val/total*100)});
            angle=next;
        });
        ctx.globalCompositeOperation='destination-out';ctx.beginPath();ctx.arc(cx,cy,inner,0,Math.PI*2);ctx.fill();ctx.globalCompositeOperation='source-over';
        text(ctx,total.toLocaleString('th-TH'),cx-12,cy+4,18,'700');
        text(ctx,'รายการ',cx-15,cy+20,9);
        labels.forEach((x,i)=>{const y=25+i*28;ctx.fillStyle=['#315ee8','#6f52c9','#2f9b61','#c83d50'][i%4];ctx.fillRect(w*.72,y,9,9);text(ctx,`${x.row.label} ${x.percent}%`,w*.72+15,y+9,9);});
    }

    window.renderInventoryDashboardCharts = data => {
        requestAnimationFrame(() => {
            lineChart(data.monthlyChart || []);
            barChart(data.topBorrowed || []);
            donutChart(data.statusChart || []);
        });
    };

    window.addEventListener('resize', () => {
        // Charts redraw on the next dashboard load; avoid storing stale state.
    });
})();
