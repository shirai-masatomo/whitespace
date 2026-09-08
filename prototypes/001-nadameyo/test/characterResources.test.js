import test from 'node:test'
import assert from 'node:assert/strict'
import { Scene, Group, Mesh, BoxGeometry, MeshBasicMaterial, Texture } from 'three'
import { disposeScene } from '../src/character/disposeScene.js'

test('leaving the character releases shared geometry, materials and textures once', () => {
  const scene = new Scene(), group = new Group(), geometry = new BoxGeometry(), texture = new Texture()
  const material = new MeshBasicMaterial({ map: texture })
  const counts = [0, 0, 0]
  ;[geometry, material, texture].forEach((item, index) => item.addEventListener('dispose', () => counts[index]++))
  group.add(new Mesh(geometry, material), new Mesh(geometry, [material, material]))
  scene.add(group)
  assert.equal(disposeScene(scene), 3)
  assert.deepEqual(counts, [1, 1, 1]); assert.equal(scene.children.length, 0)
  assert.equal(disposeScene(scene), 0)
  assert.deepEqual(counts, [1, 1, 1])
})
