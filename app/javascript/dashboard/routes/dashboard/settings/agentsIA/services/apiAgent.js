import axios from 'axios'

// const baseUrl='http://localhost:8080/api'; //Desarrollo
const baseUrl='http://34.41.191.74:8081/api'; //!Produccion

const apiAgent = axios.create({
  baseURL: baseUrl,
  headers: {
    'Content-Type': 'application/json',
  },
})

export default apiAgent
