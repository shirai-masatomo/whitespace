// Shared geometry/materials and texture references are released exactly once.
export function disposeScene(scene) {
  const resources = new Set()
  scene.traverse((object) => {
    if (object.geometry) resources.add(object.geometry)
    for (const material of [object.material].flat().filter(Boolean)) {
      resources.add(material)
      for (const value of Object.values(material)) if (value?.isTexture) resources.add(value)
    }
  })
  resources.forEach((resource) => resource.dispose())
  scene.clear()
  return resources.size
}
