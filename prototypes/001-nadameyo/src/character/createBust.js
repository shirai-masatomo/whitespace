import * as THREE from 'three'

// A few rings define the silhouette. Triangles are deliberately unshared so
// each face has its own matte normal and can open a very small seam.
function ringsGeometry(rings, sides = 10) {
  const vertices = []
  const points = rings.map(([y, width, depth]) => Array.from({ length: sides }, (_, i) => {
    const angle = i / sides * Math.PI * 2
    return new THREE.Vector3(Math.sin(angle) * width, y, Math.cos(angle) * depth)
  }))
  for (let r = 0; r < rings.length - 1; r++) for (let i = 0; i < sides; i++) {
    const j = (i + 1) % sides
    for (const p of [points[r][i], points[r][j], points[r + 1][i], points[r][j], points[r + 1][j], points[r + 1][i]]) vertices.push(...p)
  }
  const geometry = new THREE.BufferGeometry()
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3))
  geometry.computeVertexNormals()
  return geometry
}

function faceted(geometry, material) {
  const position = geometry.attributes.position
  const base = new Float32Array(position.array)
  const colors = []
  for (let i = 0; i < position.count; i += 3) {
    const shade = .82 + .16 * ((i * 17 % 31) / 31)
    const center = new THREE.Vector3()
    for (let j = 0; j < 3; j++) center.add(new THREE.Vector3().fromBufferAttribute(position, i + j))
    center.divideScalar(3)
    for (let j = 0; j < 3; j++) {
      const k = (i + j) * 3
      base[k] = center.x + (base[k] - center.x) * .987
      base[k + 1] = center.y + (base[k + 1] - center.y) * .987
      base[k + 2] = center.z + (base[k + 2] - center.z) * .987
      colors.push(shade, shade, shade)
    }
  }
  geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3))
  position.array.set(base)
  const mesh = new THREE.Mesh(geometry, material)
  mesh.userData.base = base
  return mesh
}

export function createBust(root = new THREE.Group()) {
  const stone = new THREE.MeshStandardMaterial({ color: '#cdd0cb', roughness: .96, metalness: 0, flatShading: true, vertexColors: true })
  const plain = new THREE.MeshStandardMaterial({ color: '#b9c1bc', roughness: 1, flatShading: true })
  const innerMaterial = new THREE.MeshStandardMaterial({ color: '#68746f', emissive: '#aac4ac', emissiveIntensity: .08, roughness: 1 })
  const torso = faceted(ringsGeometry([[-.65, .61, .27], [-.25, .76, .36], [.32, .93, .41], [.58, .86, .32], [.88, .25, .2]]), stone)
  root.add(torso)
  const shoulders = [-1, 1].map((side) => {
    const shoulder = new THREE.Mesh(new THREE.IcosahedronGeometry(.45, 0), plain)
    shoulder.position.set(side * .73, .43, -.04)
    shoulder.scale.set(1, .55, .85)
    shoulder.rotation.z = side * -.2
    root.add(shoulder)
    return shoulder
  })
  const neck = new THREE.Mesh(new THREE.CylinderGeometry(.19, .24, .49, 7), plain)
  neck.position.y = 1.02
  root.add(neck)
  const head = new THREE.Group()
  head.position.set(0, 1.17, .015)
  const headGeometry = ringsGeometry([[0, .12, .19], [.15, .31, .32], [.48, .43, .46], [.83, .45, .4], [1.12, .34, .32], [1.28, .015, .02]])
  const face = faceted(headGeometry, stone)
  head.add(face)
  // A quiet central ridge makes turning readable without eyes or a mouth.
  const ridgeGeometry = new THREE.BufferGeometry()
  ridgeGeometry.setAttribute('position', new THREE.Float32BufferAttribute([
    -.065, .59, .42, 0, .39, .56, .065, .59, .42,
    -.065, .59, .42, 0, .32, .42, 0, .39, .56,
    .065, .59, .42, 0, .39, .56, 0, .32, .42,
  ], 3))
  ridgeGeometry.computeVertexNormals()
  head.add(new THREE.Mesh(ridgeGeometry, plain))
  const inner = new THREE.Mesh(new THREE.IcosahedronGeometry(.52, 1), innerMaterial)
  inner.position.y = .63; inner.scale.set(.78, 1.14, .7)
  head.add(inner)
  root.add(head)

  const coreMaterial = new THREE.MeshBasicMaterial({ color: '#e4efd3' })
  const core = new THREE.Mesh(new THREE.OctahedronGeometry(.075, 0), coreMaterial)
  core.position.set(0, .32, .435); core.scale.y = 1.8
  root.add(core)
  const light = new THREE.PointLight('#d2e6c2', .5, 2, 2)
  light.position.set(0, .32, .7); root.add(light)
  const canvas = document.createElement('canvas')
  canvas.width = canvas.height = 64
  const context = canvas.getContext('2d')
  const gradient = context.createRadialGradient(32, 32, 0, 32, 32, 32)
  gradient.addColorStop(0, 'rgba(208,233,184,.7)'); gradient.addColorStop(.25, 'rgba(180,213,165,.18)'); gradient.addColorStop(1, 'rgba(180,213,165,0)')
  context.fillStyle = gradient; context.fillRect(0, 0, 64, 64)
  const texture = new THREE.CanvasTexture(canvas)
  const glow = new THREE.Sprite(new THREE.SpriteMaterial({ map: texture, transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }))
  glow.position.copy(core.position); glow.position.z += .09
  root.add(glow)
  const base = new THREE.Mesh(new THREE.CylinderGeometry(.68, .73, .09, 12), new THREE.MeshStandardMaterial({ color: '#263335', roughness: 1 }))
  base.position.y = -.72; root.add(base)

  return {
    root,
    apply(pose, reaction, time, reduced) {
      const sway = reduced ? 0 : Math.sin(time * .8) * pose.breath
      const tremor = reduced ? 0 : Math.sin(time * 12) * Math.sin(time * 7) * pose.tremor * (1 - reaction.settle)
      root.rotation.y = pose.yaw * .22
      head.rotation.set(pose.pitch, pose.yaw * .78 + tremor, reaction.tilt + sway)
      root.position.y = sway * .4
      shoulders.forEach((shoulder) => { shoulder.position.y = .43 + pose.shoulder - reaction.shoulderDrop })
      glow.scale.setScalar(.48 + pose.spread * .95)
      glow.material.opacity = pose.light * .72
      core.scale.x = .7 + pose.spread; core.scale.z = .7 + pose.spread
      coreMaterial.color.setRGB(.35 + pose.light * .6, .4 + pose.light * .55, .3 + pose.light * .55)
      light.intensity = pose.light * .9
      innerMaterial.emissiveIntensity = pose.light * .22
      const positions = face.geometry.attributes.position
      const normals = face.geometry.attributes.normal.array
      const original = face.userData.base
      for (let i = 0; i < positions.count; i++) {
        const triangle = Math.floor(i / 3)
        const separation = pose.separation * (.5 + .5 * Math.sin(triangle * 2.4 + (reduced ? 0 : time * .7 * pose.surfaceMotion)))
        for (let axis = 0; axis < 3; axis++) positions.array[i * 3 + axis] = original[i * 3 + axis] + normals[i * 3 + axis] * separation
      }
      positions.needsUpdate = true
    },
  }
}
