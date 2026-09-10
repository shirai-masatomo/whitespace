import { mkdir, readFile, writeFile } from 'node:fs/promises'
const directory = new URL('../../../.tmp-docs/', import.meta.url)
await mkdir(directory, { recursive: true })
const markdown = await readFile(new URL('../../../docs/COFFEE_FLOW.md', import.meta.url), 'utf8')
const diagrams = [...markdown.matchAll(/```mermaid\r?\n([\s\S]*?)```/g)]
for (const [index, diagram] of diagrams.entries()) {
  await writeFile(new URL(`coffee-${index + 1}.mmd`, directory), diagram[1])
}
console.log(`${diagrams.length}図を .tmp-docs/coffee-*.mmd に抽出しました。Markdownは変更していません。`)
