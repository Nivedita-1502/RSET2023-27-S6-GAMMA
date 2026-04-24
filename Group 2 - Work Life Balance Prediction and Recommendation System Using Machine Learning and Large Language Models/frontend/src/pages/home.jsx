import { useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import { getDashboard, deleteProfile } from "../services/api";
import bg from "../assets/bg_wlb.png";

export default function Home(){

  const navigate = useNavigate();
  const [hasData,setHasData] = useState(false);
  const [showMenu,setShowMenu] = useState(false);

  useEffect(()=>{

    async function checkUserData(){
      try{
        const res = await getDashboard();

        if(res.data && !res.data.message){
          setHasData(true);
        }
      }
      catch(err){
        console.log("Dashboard check failed");
      }
    }

    checkUserData();

  },[]);

  const goToDashboard = () => {

    if(!hasData){
      alert("Please complete the questionnaire first.");
      return;
    }

    navigate("/dashboard");
  };

  const goToQuestionnaire = () => {
    navigate("/weekly-checkin");
  };

  const goToProfile = () => {
    navigate("/profile");
  };

  const logout = () => {
    localStorage.removeItem("token");
    navigate("/login");
  };

  const handleDelete = async () => {

    const confirmDelete = window.confirm("Are you sure you want to delete your account?");

    if(!confirmDelete) return;

    await deleteProfile();

    localStorage.removeItem("token");

    navigate("/signup");
  };

  return(

  <div style={{
    height:"100vh",
    display:"flex",
    justifyContent:"center",
    alignItems:"center",
    background:"linear-gradient(135deg,#EAF4FF,#D6E8FF)",
    backgroundImage: `url(${bg})`,
    fontFamily:"Segoe UI"
  }}>

  {/* PROFILE DROPDOWN */}

  <div style={{
    position:"absolute",
    top:"20px",
    right:"30px"
  }}>

    <button
      onClick={()=>setShowMenu(!showMenu)}
      style={{
        padding:"10px 16px",
        borderRadius:"8px",
        border:"none",
        background:"#0A4D8C",
        color:"white",
        cursor:"pointer"
      }}
    >
      View Profile ▼
    </button>

    {showMenu && (

      <div style={{
        background:"white",
        boxShadow:"0 5px 15px rgba(0,0,0,0.2)",
        borderRadius:"8px",
        marginTop:"8px",
        overflow:"hidden"
      }}>

        <div
          onClick={goToProfile}
          style={menuItem}
        >
          View / Update Profile
        </div>

        <div
          onClick={logout}
          style={menuItem}
        >
          Sign Out
        </div>

        <div
          onClick={handleDelete}
          style={{...menuItem,color:"red"}}
        >
          Delete Account
        </div>

      </div>

    )}

  </div>

  {/* MAIN CARD */}

  <div style={{
    background:"white",
    padding:"50px",
    borderRadius:"16px",
    boxShadow:"0 10px 30px rgba(0,0,0,0.15)",
    textAlign:"center",
    width:"420px"
  }}>

  <h1 style={{color:"#0A4D8C"}}>
  LifeBalance AI
  </h1>

  <p style={{marginBottom:"30px",color:"#555"}}>
  Choose where you want to go
  </p>

  <button
  onClick={goToQuestionnaire}
  style={{
    width:"100%",
    padding:"12px",
    marginBottom:"15px",
    background:"#2F80ED",
    color:"white",
    border:"none",
    borderRadius:"8px",
    cursor:"pointer",
    fontSize:"16px"
  }}
  >
  Go to Questionnaire
  </button>

  <button
  onClick={goToDashboard}
  style={{
    width:"100%",
    padding:"12px",
    background:"#0A4D8C",
    color:"white",
    border:"none",
    borderRadius:"8px",
    cursor:"pointer",
    fontSize:"16px"
  }}
  >
  Go to Dashboard
  </button>

  </div>
  </div>

  );
}

const menuItem = {
  padding:"10px 20px",
  cursor:"pointer",
  borderBottom:"1px solid #eee"
};