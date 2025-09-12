import axios from 'axios'

// export const baseUrl='http://localhost:8080'; //Desarrollo
export const baseUrl='http://34.41.191.74:8081'; //!Produccion

const apiAgent = axios.create({
  baseURL: baseUrl,
  headers: {
    'Content-Type': 'application/json',
  },
})

export default apiAgent
