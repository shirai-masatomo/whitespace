import { existsSync, readdirSync, readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
const root = fileURLToPath(new URL('../../../', import.meta.url))
function markdownFiles(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
    const path = resolve(directory, entry.name)
    return entry.isDirectory() ? markdownFiles(path) : path.endsWith('.md') ? [path] : []
  })
}
const files = [resolve(root, 'README.md'), resolve(root, 'AGENTS.md'), resolve(root, 'prototypes/001-nadameyo/README.md'), ...markdownFiles(resolve(root, 'docs'))]
const broken = []
for (const file of files) {
  const content = readFileSync(file, 'utf8').replace(/```[\s\S]*?```/g, '')
  for (const match of content.matchAll(/\]\(([^)]+)\)/g)) {
    const link = match[1].split('#')[0]
    if (!link || /^[a-z]+:/i.test(link)) continue
    if (!existsSync(resolve(dirname(file), decodeURIComponent(link)))) broken.push({ file, link })
  }
}
console.log({ documents: files.length, broken })
if (broken.length) process.exitCode = 1
