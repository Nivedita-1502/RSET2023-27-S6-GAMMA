import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { getProfile, deleteProfile } from "../services/api";

export default function Profile(){

  const navigate = useNavigate();

  const [profile,setProfile] = useState({});

  useEffect(()=>{

    async function loadProfile(){
      const res = await getProfile();
      setProfile(res.data);
    }

    loadProfile();

  },[]);

  const handleUpdate = () => {
    navigate("/profile-setup", { state: profile });
  };

  const handleDelete = async()=>{
    await deleteProfile();
    alert("Account deleted");
    navigate("/signup");
  }

  return(

  <div className="page-container">

    <div className="form-card">

      <h2 className="page-title">Profile</h2>

      <p><b>Name:</b> {profile.name}</p>
      <p><b>Email:</b> {profile.email}</p>
      <p><b>Age:</b> {profile.age}</p>
      <p><b>Department:</b> {profile.department}</p>
      <p><b>Role Level:</b> {profile.role_level}</p>
      <p><b>Work Mode:</b> {profile.work_mode}</p>
      <p><b>Commute Time:</b> {profile.commute_time}</p>

      <button
      onClick={handleUpdate}
      className="primary-btn"
      >
        Update Profile
      </button>

      <button
      onClick={handleDelete}
      className="danger-btn"
      >
        Delete Account
      </button>

    </div>

  </div>

  )
}