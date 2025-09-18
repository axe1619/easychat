import axios from 'axios'



export const frontUrl = process.env.FRONTEND_URL
export const baseUrl = process.env.AGENTIC_EASY_CONTACT
// export const baseUrl='http://localhost:8080'; //Desarrollo
// export const baseUrl='http://34.41.191.74:8081'; //!Produccion

const apiAgent = axios.create({
  baseURL: baseUrl,
  headers: {
    'Content-Type': 'application/json',
  },
})

export default apiAgent
