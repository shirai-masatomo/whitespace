import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import Jenga from './Jenga.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <Jenga />
  </StrictMode>,
)
