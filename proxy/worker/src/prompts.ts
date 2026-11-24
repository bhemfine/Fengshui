import type { JsonSchema } from "./validate";

import floorPlanSystem from "../../prompts/floor_plan_reading.system.md";
import palmSystem from "../../prompts/palm_reading.system.md";
import houseSystem from "../../prompts/house_check.system.md";
import dailySystem from "../../prompts/daily_writeup.system.md";
import monthlySystem from "../../prompts/monthly_writeup.system.md";
import yearlySystem from "../../prompts/yearly_writeup.system.md";
import compatSystem from "../../prompts/compatibility.system.md";
import askSystem from "../../prompts/ask_the_master.system.md";

import floorPlanSchema from "../../prompts/floor_plan_reading.schema.json";
import palmSchema from "../../prompts/palm_reading.schema.json";
import houseSchema from "../../prompts/house_check.schema.json";
import dailySchema from "../../prompts/daily_writeup.schema.json";
import monthlySchema from "../../prompts/monthly_writeup.schema.json";
import yearlySchema from "../../prompts/yearly_writeup.schema.json";
import compatSchema from "../../prompts/compatibility.schema.json";
import askSchema from "../../prompts/ask_the_master.schema.json";

export type TaskName =
  | "floor_plan_reading"
  | "palm_reading"
  | "house_check"
  | "daily_writeup"
  | "monthly_writeup"
  | "yearly_writeup"
  | "compatibility"
  | "ask_the_master";

export interface TaskDef {
  system: string;
  schema: JsonSchema;
  maxTokens: number;
  temperature: number;
  minImages: number;
  maxImages: number;
}

const s = (x: unknown): JsonSchema => x as JsonSchema;

export const TASKS: Record<TaskName, TaskDef> = {
  floor_plan_reading: { system: floorPlanSystem, schema: s(floorPlanSchema), maxTokens: 3000, temperature: 0.2, minImages: 1, maxImages: 1 },
  palm_reading: { system: palmSystem, schema: s(palmSchema), maxTokens: 2000, temperature: 0.4, minImages: 1, maxImages: 1 },
  house_check: { system: houseSystem, schema: s(houseSchema), maxTokens: 2000, temperature: 0.2, minImages: 1, maxImages: 4 },
  daily_writeup: { system: dailySystem, schema: s(dailySchema), maxTokens: 900, temperature: 0.6, minImages: 0, maxImages: 0 },
  monthly_writeup: { system: monthlySystem, schema: s(monthlySchema), maxTokens: 1500, temperature: 0.6, minImages: 0, maxImages: 0 },
  yearly_writeup: { system: yearlySystem, schema: s(yearlySchema), maxTokens: 2200, temperature: 0.6, minImages: 0, maxImages: 0 },
  compatibility: { system: compatSystem, schema: s(compatSchema), maxTokens: 1600, temperature: 0.5, minImages: 0, maxImages: 0 },
  ask_the_master: { system: askSystem, schema: s(askSchema), maxTokens: 1500, temperature: 0.4, minImages: 0, maxImages: 0 },
};

export function isTaskName(x: string): x is TaskName {
  return Object.prototype.hasOwnProperty.call(TASKS, x);
}
