import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { login } from "../services/api";
import { FaUserAlt, FaLock } from "react-icons/fa";
import bg from "../assets/bg_wlb.png"; 

export default function Login(){

  const navigate = useNavigate();

  const [data,setData] = useState({
    email:"",
    password:""
  });

  const [error,setError] = useState("");

  const handleSubmit = async(e)=>{
    e.preventDefault();

    setError("");

    try{

      const res = await login(data);

      localStorage.setItem("token",res.data.access_token);
      localStorage.setItem("email",data.email);

      navigate("/home");

    }
    catch(err){

      if(err.response?.status === 401){
        setError("Incorrect email or password.");
      }
      else{
        setError("Login failed. Please try again.");
      }

    }
  }

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
marginBottom:"25px"
}}>
Login to continue your work‑life balance journey
</p>

{/* ERROR MESSAGE */}

{error && (
<div style={{
background:"#ffe6e6",
color:"#cc0000",
padding:"10px",
borderRadius:"6px",
marginBottom:"15px",
fontSize:"14px"
}}>
{error}
</div>
)}

{/* EMAIL */}

<div style={{
display:"flex",
alignItems:"center",
border:"1px solid #ddd",
borderRadius:"8px",
padding:"10px",
marginBottom:"20px",
background:"#fafafa"
}}>

<FaUserAlt style={{marginRight:"10px",color:"#0A4D8C"}}/>

<input
placeholder="Email"
style={{
border:"none",
outline:"none",
width:"100%",
background:"transparent"
}}
onChange={(e)=>setData({...data,email:e.target.value})}
/>

</div>

{/* PASSWORD */}

<div style={{
display:"flex",
alignItems:"center",
border:"1px solid #ddd",
borderRadius:"8px",
padding:"10px",
marginBottom:"25px",
background:"#fafafa"
}}>

<FaLock style={{marginRight:"10px",color:"#0A4D8C"}}/>

<input
type="password"
placeholder="Password"
style={{
border:"none",
outline:"none",
width:"100%",
background:"transparent"
}}
onChange={(e)=>setData({...data,password:e.target.value})}
/>

</div>

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
Login
</button>

<p style={{
marginTop:"18px",
fontSize:"13px",
color:"#666"
}}>
Don't have an account? <span
style={{color:"#2F80ED",cursor:"pointer"}}
onClick={()=>navigate("/signup")}
>
Sign up
</span>
</p>

</form>

</div>

  );
}