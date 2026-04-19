import { motion } from "framer-motion";

export default function SlideCard({children}){

return(

<motion.div
className="card"
initial={{x:100,opacity:0}}
animate={{x:0,opacity:1}}
transition={{duration:0.5}}
>

{children}

</motion.div>

)

}