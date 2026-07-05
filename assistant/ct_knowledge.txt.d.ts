// Type shim so TypeScript accepts `import CT_DOCS from "./ct_knowledge.txt"`.
// The actual bundling is done by the [[rules]] Text rule in wrangler.toml.
declare module "*.txt" {
  const content: string;
  export default content;
}
