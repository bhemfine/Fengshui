// Lightweight JSON Schema subset validator (draft 2020-12 keywords used by our prompts).
// Supports: $ref (#/$defs/...), type (string or array), enum, const, properties,
// required, additionalProperties:false, items, minItems, maxItems, minLength,
// maxLength, minimum, maximum.

export interface JsonSchema {
  $ref?: string;
  $defs?: Record<string, JsonSchema>;
  type?: string | string[];
  enum?: readonly unknown[];
  const?: unknown;
  properties?: Record<string, JsonSchema>;
  required?: string[];
  additionalProperties?: boolean;
  items?: JsonSchema;
  minItems?: number;
  maxItems?: number;
  minLength?: number;
  maxLength?: number;
  minimum?: number;
  maximum?: number;
  [key: string]: unknown;
}

export function validate(schema: JsonSchema, value: unknown, maxErrors = 20): string[] {
  const errors: string[] = [];
  walk(schema, value, schema, "$", errors, maxErrors);
  return errors;
}

function resolve(s: JsonSchema, root: JsonSchema): JsonSchema {
  if (typeof s.$ref !== "string") return s;
  const m = /^#\/\$defs\/(.+)$/.exec(s.$ref);
  const target = m && root.$defs ? root.$defs[m[1]] : undefined;
  if (!target) throw new Error("unresolvable $ref");
  return target;
}

function typeOf(v: unknown): string {
  if (v === null) return "null";
  if (Array.isArray(v)) return "array";
  return typeof v;
}

function matchesType(t: string, v: unknown): boolean {
  switch (t) {
    case "null": return v === null;
    case "array": return Array.isArray(v);
    case "object": return typeof v === "object" && v !== null && !Array.isArray(v);
    case "integer": return typeof v === "number" && Number.isInteger(v);
    case "number": return typeof v === "number" && Number.isFinite(v);
    case "string": return typeof v === "string";
    case "boolean": return typeof v === "boolean";
    default: return false;
  }
}

function walk(raw: JsonSchema, v: unknown, root: JsonSchema, path: string, errors: string[], max: number): void {
  if (errors.length >= max) return;
  const s = resolve(raw, root);

  if (s.type !== undefined) {
    const types = Array.isArray(s.type) ? s.type : [s.type];
    if (!types.some((t) => matchesType(t, v))) {
      errors.push(`${path}: expected ${types.join("|")}, got ${typeOf(v)}`);
      return;
    }
  }
  if (s.enum && !s.enum.some((e) => e === v)) {
    errors.push(`${path}: value not in enum`);
    return;
  }
  if ("const" in s && s.const !== v) {
    errors.push(`${path}: const mismatch`);
    return;
  }
  if (typeof v === "number") {
    if (s.minimum !== undefined && v < s.minimum) errors.push(`${path}: below minimum`);
    if (s.maximum !== undefined && v > s.maximum) errors.push(`${path}: above maximum`);
  }
  if (typeof v === "string") {
    if (s.minLength !== undefined && v.length < s.minLength) errors.push(`${path}: too short`);
    if (s.maxLength !== undefined && v.length > s.maxLength) errors.push(`${path}: too long`);
  }
  if (Array.isArray(v)) {
    if (s.minItems !== undefined && v.length < s.minItems) errors.push(`${path}: too few items`);
    if (s.maxItems !== undefined && v.length > s.maxItems) errors.push(`${path}: too many items`);
    if (s.items) {
      const itemSchema = s.items;
      v.forEach((item, i) => walk(itemSchema, item, root, `${path}[${i}]`, errors, max));
    }
  }
  if (typeof v === "object" && v !== null && !Array.isArray(v)) {
    const obj = v as Record<string, unknown>;
    for (const key of s.required ?? []) {
      if (!(key in obj)) errors.push(`${path}.${key}: required`);
    }
    const props = s.properties ?? {};
    for (const [key, val] of Object.entries(obj)) {
      const ps = props[key];
      if (ps) walk(ps, val, root, `${path}.${key}`, errors, max);
      else if (s.additionalProperties === false) errors.push(`${path}.${key}: not allowed`);
    }
  }
}
