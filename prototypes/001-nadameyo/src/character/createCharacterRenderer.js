import * as THREE from 'three'
import { createBust } from './createBust.js'
import { disposeScene } from './disposeScene.js'
import { createReactionController, easePose } from '../lib/characterState.js'

let activeRenderers = 0

// Instance-owned resources and loop. Disposing is safe more than once.
export function createCharacterRenderer(host, initial, onFailure) {
  const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true, powerPreference: 'low-power' })
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.75))
  renderer.setClearColor(0x000000, 0)
  renderer.outputColorSpace = THREE.SRGBColorSpace
  const scene = new THREE.Scene()
  const camera = new THREE.OrthographicCamera(-2, 2, 2, -2, .1, 20)
  camera.position.set(0, .86, 7); camera.lookAt(0, .86, 0)
  scene.add(new THREE.HemisphereLight('#dfe8e6', '#263237', 1.35))
  const key = new THREE.DirectionalLight('#f1f4ef', 2.8); key.position.set(-3, 5, 4); scene.add(key)
  const rim = new THREE.DirectionalLight('#9bbbc7', 2.6); rim.position.set(3, 2, -3); scene.add(rim)
  const root = new THREE.Group(); scene.add(root)
  let bust
  try { bust = createBust(root) }
  catch (error) { disposeScene(scene); renderer.dispose(); renderer.forceContextLoss(); throw error }
  host.appendChild(renderer.domElement)
  activeRenderers++
  if (import.meta.env.DEV) console.debug(`[Character3D] created; active=${activeRenderers}`)
  const reactions = createReactionController()
  let target = initial.pose
  let current = { ...target }
  let reduced = initial.reduced
  let disposed = false
  let frame = null
  let previous = performance.now()
  let time = 0
  reactions.receive(initial.event, time)
  function resize() {
    const { width, height } = host.getBoundingClientRect()
    if (!width || !height || disposed) return
    renderer.setSize(width, height)
    const half = 1.84
    camera.left = -half * width / height; camera.right = half * width / height
    camera.top = half; camera.bottom = -half; camera.updateProjectionMatrix()
  }
  const observer = new ResizeObserver(resize); observer.observe(host); resize()
  function dispose() {
    if (disposed) return
    disposed = true
    cancelAnimationFrame(frame)
    observer.disconnect()
    document.removeEventListener('visibilitychange', visibility)
    renderer.domElement.removeEventListener('webglcontextlost', lost)
    const released = disposeScene(scene)
    renderer.dispose(); renderer.forceContextLoss(); renderer.domElement.remove()
    activeRenderers--
    if (import.meta.env.DEV) console.debug(`[Character3D] disposed; active=${activeRenderers}; released=${released}`)
  }
  function lost(event) { event.preventDefault(); dispose(); onFailure('3Dの接続が失われました。会話は続けられます。') }
  renderer.domElement.addEventListener('webglcontextlost', lost)
  function tick(now) {
    if (disposed) return
    const delta = Math.min((now - previous) / 1000, .05); previous = now; time += delta
    current = easePose(current, target, delta)
    bust.apply(current, reactions.sample(time, reduced), time, reduced)
    try { renderer.render(scene, camera) } catch { dispose(); onFailure('3Dを描画できません。会話は続けられます。'); return }
    frame = requestAnimationFrame(tick)
  }
  function visibility() {
    cancelAnimationFrame(frame)
    if (!document.hidden && !disposed) { previous = performance.now(); frame = requestAnimationFrame(tick) }
  }
  document.addEventListener('visibilitychange', visibility)
  frame = requestAnimationFrame(tick)
  return { dispose, loseContext() { renderer.forceContextLoss() },
    update(next) { if (disposed) return; target = next.pose; reduced = next.reduced; reactions.receive(next.event, time) } }
}
