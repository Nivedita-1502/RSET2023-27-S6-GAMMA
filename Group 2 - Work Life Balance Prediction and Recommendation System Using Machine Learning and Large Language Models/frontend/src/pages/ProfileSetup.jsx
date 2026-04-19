import { useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { saveProfile } from "../services/api";
import bg from "../assets/bg_wlb.png";

export default function ProfileSetup(){

  const location = useLocation();
  const navigate = useNavigate();

  const existingData = location.state;

  const [profile,setProfile] = useState(

    existingData || {

      email:"",
      age_group:"",
      marital_status:"",
      children:"",

      department:"",
      role_level:"",

      work_mode:"",
      official_work_hours:"",
      commute_time:""
    }
  );

  useEffect(()=>{

    if(!existingData){
      const email = localStorage.getItem("email");

      if(email){
        setProfile(prev => ({...prev,email}));
      }
    }

  },[]);


  const handleSubmit = async(e)=>{

    e.preventDefault();

    try{

      await saveProfile(profile);

      alert("Profile saved successfully");

      navigate("/home");

    }
    catch(err){
      alert("Error saving profile");
    }
  };

  return(

  <div className="page-container">

  <form onSubmit={handleSubmit} className="form-card">

    <h2 className="page-title">Profile Setup</h2>

    <p className="email-display">Email: {profile.email}</p>


    <div className="form-section">

    <h3>Personal Context</h3>

    <select
    value={profile.age_group}
    onChange={(e)=>setProfile({...profile,age_group:e.target.value})}>
      <option value="">Select Age Group</option>
      <option value="18-25">18-25</option>
      <option value="26-35">26-35</option>
      <option value="36-45">36-45</option>
      <option value="46-55">46-55</option>
      <option value="55+">55+</option>
    </select>

    <select
    value={profile.marital_status}
    onChange={(e)=>setProfile({...profile,marital_status:e.target.value})}>
      <option value="">Marital Status</option>
      <option value="Single">Single</option>
      <option value="Married">Married</option>
      <option value="Divorced / Separated">Divorced / Separated</option>
      <option value="Widowed">Widowed</option>
      <option value="Prefer not to say">Prefer not to say</option>
    </select>

    <select
    value={profile.children}
    onChange={(e)=>setProfile({...profile,children:e.target.value})}>
      <option value="">Children</option>
      <option value="No children">No children</option>
      <option value="1 child">1 child</option>
      <option value="2 children">2 children</option>
      <option value="3 or more children">3 or more children</option>
    </select>

    </div>


    <div className="form-section">

    <h3>Work Context</h3>

    <input
      value={profile.department}
      placeholder="Department"
      onChange={(e)=>setProfile({...profile,department:e.target.value})}
    />

    <input
      value={profile.role_level}
      placeholder="Role Level"
      onChange={(e)=>setProfile({...profile,role_level:e.target.value})}
    />

    </div>


    <div className="form-section">

    <h3>Work Structure</h3>

    <select
    value={profile.work_mode}
    onChange={(e)=>setProfile({...profile,work_mode:e.target.value})}>
      <option value="">Work Mode</option>
      <option value="Work From Home">Work From Home</option>
      <option value="Hybrid">Hybrid</option>
      <option value="Office Only">Office Only</option>
    </select>

    <select
    value={profile.official_work_hours}
    onChange={(e)=>setProfile({...profile,official_work_hours:e.target.value})}>
      <option value="">Work Hours</option>
      <option value="8 AM – 4 PM">8 AM – 4 PM</option>
      <option value="9 AM – 5 PM">9 AM – 5 PM</option>
      <option value="10 AM – 6 PM">10 AM – 6 PM</option>
      <option value="11 AM – 7 PM">11 AM – 7 PM</option>
      <option value="Rotational Shift">Rotational Shift</option>
      <option value="Night Shift">Night Shift</option>
    </select>

    </div>


    <div className="form-section">

    <h3>Commute</h3>

    <select
    value={profile.commute_time}
    onChange={(e)=>setProfile({...profile,commute_time:e.target.value})}>
      <option value="">Commute Time</option>
      <option value="No commute (Work From Home)">No commute (Work From Home)</option>
      <option value="Less than 30 minutes">Less than 30 minutes</option>
      <option value="30 – 60 minutes">30 – 60 minutes</option>
      <option value="1 – 2 hours">1 – 2 hours</option>
      <option value="More than 2 hours">More than 2 hours</option>
    </select>

    </div>

    <button type="submit">Save Profile</button>

  </form>

  </div>
  );
}