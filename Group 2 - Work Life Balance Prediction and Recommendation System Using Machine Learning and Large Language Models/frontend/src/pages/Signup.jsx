import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { signup } from "../services/api";
import bg from "../assets/bg_wlb.png"; 

export default function Signup() {

  const navigate = useNavigate();

  const [form,setForm] = useState({
    name:"",
    age:0,
    email:"",
    password:""
  });

  const handleSubmit = async(e)=>{
    e.preventDefault();

    const res = await signup(form);

    localStorage.setItem("token", res.data.access_token);
    localStorage.setItem("email", form.email);
    localStorage.removeItem("latest_result");

    navigate("/profile-setup");
  };

  return (

<div style={{
height:"100vh",
display:"flex",
justifyContent:"center",
alignItems:"center",
background:"linear-gradient(135deg,#EAF4FF,#D6E8FF)",
backgroundImage: `url(${bg})`,
fontFamily:"Segoe UI"
}}>

<form
onSubmit={handleSubmit}
style={{
background:"white",
padding:"45px",
borderRadius:"16px",
width:"380px",
boxShadow:"0 12px 35px rgba(0,0,0,0.15)",
textAlign:"center"
}}
>

<h1 style={{
color:"#0A4D8C",
marginBottom:"5px"
}}>
LifeBalance AI
</h1>

<p style={{
fontSize:"14px",
color:"#666",
marginBottom:"30px"
}}>
Create your account to start improving your work‑life balance
</p>

{/* NAME */}

<input
placeholder="Name"
style={{
width:"100%",
padding:"10px",
border:"1px solid #ddd",
borderRadius:"8px",
marginBottom:"15px",
background:"#fafafa",
outline:"none"
}}
onChange={(e)=>setForm({...form,name:e.target.value})}
/>

{/* AGE */}

<input
type="number"
placeholder="Age"
style={{
width:"100%",
padding:"10px",
border:"1px solid #ddd",
borderRadius:"8px",
marginBottom:"15px",
background:"#fafafa",
outline:"none"
}}
onChange={(e)=>setForm({...form,age:parseInt(e.target.value)})}
/>

{/* EMAIL */}

<input
placeholder="Email"
style={{
width:"100%",
padding:"10px",
border:"1px solid #ddd",
borderRadius:"8px",
marginBottom:"15px",
background:"#fafafa",
outline:"none"
}}
onChange={(e)=>setForm({...form,email:e.target.value})}
/>

{/* PASSWORD */}

<input
type="password"
placeholder="Password"
style={{
width:"100%",
padding:"10px",
border:"1px solid #ddd",
borderRadius:"8px",
marginBottom:"25px",
background:"#fafafa",
outline:"none"
}}
onChange={(e)=>setForm({...form,password:e.target.value})}
/>

{/* BUTTON */}

<button
type="submit"
style={{
width:"100%",
padding:"12px",
background:"linear-gradient(135deg,#0A4D8C,#2F80ED)",
border:"none",
borderRadius:"8px",
color:"white",
fontSize:"16px",
fontWeight:"600",
cursor:"pointer"
}}
>
Create Account
</button>

<p style={{
marginTop:"18px",
fontSize:"13px",
color:"#666"
}}>
Already have an account? <span
style={{color:"#2F80ED",cursor:"pointer"}}
onClick={()=>navigate("/login")}
>
Login
</span>
</p>

</form>

</div>

  );
}