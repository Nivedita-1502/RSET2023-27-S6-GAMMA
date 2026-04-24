import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { submitWeekly } from "../services/api";
import SlideCard from "../components/Slidecard";
import bg from "../assets/bg_wlb.png"; 

function WeeklyCheckin(){

const navigate = useNavigate();

const [loading,setLoading] = useState(false);
const [step,setStep] = useState(1);

const [data,setData] = useState({

email:"",

hours_worked:"",
overtime_hours:"",
projects_handled:"",
meetings_count:"",

workload_rating:1,
deadline_pressure:1,

productivity_rating:1,
task_delay:"Never",

breaks:"",
break_duration:"",

sick_days:"",
leave_days:"",
exhaustion_rating:1,

travel:"No travel",
travel_enjoyment:3,

family_time:"",
social_satisfaction:3
});

useEffect(()=>{

const email = localStorage.getItem("email");

if(email){
setData(prev => ({...prev,email}));
}

},[]);

const handleSubmit = async(e)=>{

e.preventDefault();
setLoading(true);

try{

const res = await submitWeekly(data);

localStorage.setItem("latest_result",JSON.stringify(res.data));

navigate("/dashboard");

}catch(err){

console.error("Submission error:",err);
alert("Something went wrong while submitting.");

}

setLoading(false);

};

return(
    

<form onSubmit={handleSubmit} style={{maxWidth:"700px",margin:"auto"}}>

<h1 style={{textAlign:"center",color:"#0A4D8C"}}>
Weekly Work-Life Balance Questionnaire
</h1>

<p style={{textAlign:"center"}}>Email: {data.email}</p>

{loading && <p>Analyzing your work-life balance...</p>}

{/* PAGE 1 */}

{step===1 &&(

<SlideCard>

<h2>Workload</h2>

<p>How many hours did you work this week?</p>
<select required onChange={(e)=>setData({...data,hours_worked:e.target.value})}>
<option value="">Select hours worked</option>
<option value="<35">Less than 35 hours</option>
<option value="35-40">35 – 40 hours</option>
<option value="40-45">40 – 45 hours</option>
<option value="45-50">45 – 50 hours</option>
<option value=">50">More than 50 hours</option>
</select>

<p>How many overtime hours did you work?</p>
<select required onChange={(e)=>setData({...data,overtime_hours:e.target.value})}>
<option value="">Select overtime hours</option>
<option value="None">None</option>
<option value="1-5">1 – 5 hours</option>
<option value="6-10">6 – 10 hours</option>
<option value="11-15">11 – 15 hours</option>
<option value=">15">More than 15 hours</option>
</select>

<p>How many projects did you handle this week?</p>
<select required onChange={(e)=>setData({...data,projects_handled:e.target.value})}>
<option value="">Select number of projects</option>
<option value="1">1 project</option>
<option value="2-3">2 – 3 projects</option>
<option value="4-5">4 – 5 projects</option>
<option value="6-8">6 – 8 projects</option>
<option value=">8">More than 8 projects</option>
</select>

<p>How many meetings did you attend this week?</p>
<select required onChange={(e)=>setData({...data,meetings_count:e.target.value})}>
<option value="">Select meetings</option>
<option value="0-5">0 – 5 meetings</option>
<option value="6-10">6 – 10 meetings</option>
<option value="11-15">11 – 15 meetings</option>
<option value="16-20">16 – 20 meetings</option>
<option value=">20">More than 20 meetings</option>
</select>

<h3>Work Pressure</h3>

<p>How excessive did your workload feel?</p>
<input type="range" min="1" max="5"
onChange={(e)=>setData({...data,workload_rating:Number(e.target.value)})}/>

<p>How much pressure did deadlines create?</p>
<input type="range" min="1" max="5"
onChange={(e)=>setData({...data,deadline_pressure:Number(e.target.value)})}/>

<div style={{marginTop:"20px"}}>
<button type="button" onClick={()=>setStep(2)}>
Next →
</button>
</div>

</SlideCard>

)}

{/* PAGE 2 */}

{step===2 &&(

<SlideCard>

<h2>Productivity</h2>

<p>How productive did you feel during work?</p>
<input type="range" min="1" max="5"
onChange={(e)=>setData({...data,productivity_rating:Number(e.target.value)})}/>

<p>How often did you delay important tasks?</p>
<select onChange={(e)=>setData({...data,task_delay:e.target.value})}>
<option value="Never">Never</option>
<option value="Rarely">Rarely</option>
<option value="Sometimes">Sometimes</option>
<option value="Often">Often</option>
<option value="Always">Always</option>
</select>

<h3>Breaks</h3>

<p>How many breaks do you take per day?</p>
<select required onChange={(e)=>setData({...data,breaks:e.target.value})}>
<option value="">Select breaks</option>
<option value="None">No breaks</option>
<option value="1">1 break</option>
<option value="2">2 breaks</option>
<option value="3">3 breaks</option>
<option value="4+">4 or more breaks</option>
</select>

<p>How long are your typical breaks?</p>
<select required onChange={(e)=>setData({...data,break_duration:e.target.value})}>
<option value="">Select duration</option>
<option value="Less than 10 minutes">Less than 10 minutes</option>
<option value="10 – 20 minutes">10 – 20 minutes</option>
<option value="20 – 30 minutes">20 – 30 minutes</option>
<option value="30 – 45 minutes">30 – 45 minutes</option>
<option value="More than 45 minutes">More than 45 minutes</option>
</select>

<h3>Health</h3>

<p>How many sick days did you take this week?</p>
<select required onChange={(e)=>setData({...data,sick_days:e.target.value})}>
<option value="">Select sick days</option>
<option value="None">None</option>
<option value="1">1 day</option>
<option value="2">2 days</option>
<option value="3">3 days</option>
<option value="4+">4 or more days</option>
</select>

<p>How many leave days did you take?</p>
<select required onChange={(e)=>setData({...data,leave_days:e.target.value})}>
<option value="">Select leave days</option>
<option value="None">None</option>
<option value="1">1 day</option>
<option value="2">2 days</option>
<option value="3">3 days</option>
<option value="4+">4 or more days</option>
</select>

<p>How exhausted did you feel this week?</p>
<input type="range" min="1" max="5"
onChange={(e)=>setData({...data,exhaustion_rating:Number(e.target.value)})}/>

<h3>Travel</h3>

<p>How many work related trips did you make?</p>
<select onChange={(e)=>setData({...data,travel:e.target.value})}>
<option value="No travel">No travel</option>
<option value="1 trip">1 trip</option>
<option value="2 trips">2 trips</option>
<option value="3 trips">3 trips</option>
<option value="More than 3 trips">More than 3 trips</option>
</select>

<p>How enjoyable was your travel experience?</p>
<input type="range" min="1" max="5"
onChange={(e)=>setData({...data,travel_enjoyment:Number(e.target.value)})}/>

<h3>Personal Life</h3>

<p>How much time did you spend with family?</p>
<select required onChange={(e)=>setData({...data,family_time:e.target.value})}>
<option value="">Select family time</option>
<option value="<3">Less than 3 hours</option>
<option value="3-5">3 – 5 hours</option>
<option value="6-10">6 – 10 hours</option>
<option value="11-15">11 – 15 hours</option>
<option value=">15">More than 15 hours</option>
</select>

<p>How satisfied were you with your social life this week?</p>
<input type="range" min="1" max="5"
onChange={(e)=>setData({...data,social_satisfaction:Number(e.target.value)})}/>

<div style={{marginTop:"20px"}}>

<button type="button" onClick={()=>setStep(1)}>
← Back
</button>

<button type="submit" style={{marginLeft:"10px"}}>
{loading ? "Analyzing..." : "Submit Weekly Check-In"}
</button>

</div>

</SlideCard>

)}

</form>

);

}

export default WeeklyCheckin;