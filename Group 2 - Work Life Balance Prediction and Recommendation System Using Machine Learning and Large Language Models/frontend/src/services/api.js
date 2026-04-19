import axios from "axios";

const API = axios.create({
  baseURL: "http://127.0.0.1:8000",
  headers: {
    "Content-Type": "application/json"
  }
});


// ===============================
// REQUEST INTERCEPTOR
// attach JWT automatically
// ===============================

API.interceptors.request.use(
  (req) => {

    const token = localStorage.getItem("token");

    if (token) {
      req.headers.Authorization = `Bearer ${token}`;
    }

    return req;

  },
  (error) => {
    return Promise.reject(error);
  }
);


// ===============================
// RESPONSE INTERCEPTOR
// auto logout if token expires
// ===============================

API.interceptors.response.use(
  (response) => response,
  (error) => {

    if (error.response && error.response.status === 401) {

      console.log("Session expired. Logging out.");

      localStorage.removeItem("token");
      localStorage.removeItem("email");

      window.location.href = "/login";

    }

    return Promise.reject(error);

  }
);


// ===============================
// AUTH
// ===============================

export const signup = (data) => API.post("/signup", data);

export const login = (data) => API.post("/login", data);


// ===============================
// PROFILE
// ===============================

export const saveProfile = (data) =>
  API.post("/profile-setup", data);

export const updateProfile = (data) =>
  API.post("/profile-setup", data);

export const deleteProfile = () =>
  API.delete("/delete-account");

export const getProfile = () =>
  API.get("/profile");


// ===============================
// WEEKLY CHECKIN
// ===============================

export const submitWeekly = (data) =>
  API.post("/weekly-checkin", data);


// ===============================
// DASHBOARD / TREND
// ===============================

export const getDashboard = () =>
  API.get("/wlb-trend");


export default API;