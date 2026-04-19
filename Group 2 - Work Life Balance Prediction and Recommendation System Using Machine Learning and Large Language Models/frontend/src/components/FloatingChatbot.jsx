import { useState } from "react";
import Chatbot from "../pages/Chatbot";

function FloatingChatbot(){

const [open,setOpen] = useState(false);

return(

<>
{/* Floating button */}

<div
onClick={()=>setOpen(!open)}
style={{
position:"fixed",
bottom:"25px",
right:"25px",
width:"60px",
height:"60px",
background:"#0A4D8C",
borderRadius:"50%",
display:"flex",
justifyContent:"center",
alignItems:"center",
color:"white",
fontSize:"26px",
cursor:"pointer",
boxShadow:"0 5px 15px rgba(0,0,0,0.3)",
zIndex:999
}}
>
💬
</div>

{/* Chat window */}

{open && (

<div
style={{
position:"fixed",
bottom:"100px",
right:"25px",
width:"380px",
height:"500px",
background:"white",
borderRadius:"12px",
boxShadow:"0 10px 30px rgba(0,0,0,0.3)",
overflow:"hidden",
zIndex:999
}}
>

<div style={{
background:"#0A4D8C",
color:"white",
padding:"10px",
textAlign:"center",
fontWeight:"bold"
}}>
🤖
</div>

<div style={{height:"450px",overflow:"auto"}}>
<Chatbot/>
</div>

</div>

)}

</>

);

}

export default FloatingChatbot;