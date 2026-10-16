/* Run with: node prototype/core.test.cjs */
const assert = require("node:assert/strict");
const game = require("./core.js");

function test(name, run) {
  try { run(); console.log("OK " + name); }
  catch (e) { console.error("FAIL " + name); throw e; }
}

test("Starting state and specified equipment slots", () => {
  const s = game.newGame();
  assert.equal(game.SLOTS.length, 9);
  assert.deepEqual(game.SLOTS.map((row) => row[0]), [
    "head", "upper", "lower", "feet", "neck", "ears", "eyes", "finger", "arms"
  ]);
  assert.equal(s.maxReached, 1);
  assert.equal(s.party.length, 1);
  assert.equal(s.hero.equipment.upper.id, "I02");
});

test("Supply cannot enter storage and expires after expedition", () => {
  const s = game.newGame();
  assert.equal(game.act(s, "supply").ok, true);
  assert.equal(s.supplies, 2);
  assert.equal(s.bag.length, 0);
  assert.equal(game.act(s, "enter").ok, true);
  assert.equal(game.act(s, "return").ok, true);
  assert.equal(s.supplies, 0);
  assert.equal(s.stash.length, 0);
});

test("Prayer is once per expedition and improves with depth", () => {
  const s = game.newGame();
  assert.equal(game.act(s, "pray", undefined, () => 0).ok, true);
  assert.equal(s.bag.length, 1);
  assert.equal(s.bag[0].id, "I01");
  assert.equal(game.act(s, "pray").ok, false);
  game.act(s, "enter");
  game.act(s, "return");
  s.maxReached = 11;
  assert.equal(game.act(s, "pray", null, () => 0.99).ok, true);
  assert.ok(s.allies.length >= 2);
});

test("Equipment wears, breaks at zero, and can be repaired", () => {
  const s = game.newGame();
  const equip = s.hero.equipment.finger;
  equip.dur = 0;
  assert.equal(game.stats(s, "hero").atk, 6);
  s.bag.push({ uid: "manually-added-repair-stone", id: "I10", dur: null });
  assert.equal(game.act(s, "repair", { target: "hero", slot: "finger" }).ok, true);
  assert.equal(equip.dur, game.ITEMS.I05.maxDur);
  assert.equal(game.stats(s, "hero").atk, 8);
});

test("Warehouse can transfer items both directions", () => {
  const s = game.newGame();
  game.act(s, "pray", null, () => 0);
  const item = s.bag[0];
  assert.equal(game.act(s, "deposit", item.uid).ok, true);
  assert.equal(s.stash.length, 1);
  assert.equal(s.bag.length, 0);
  assert.equal(game.act(s, "withdraw", item.uid).ok, true);
  assert.equal(s.bag.length, 1);
});

test("Skill unlocks and can be reassigned in town only", () => {
  const s = game.newGame();
  assert.equal(game.act(s, "skill", "keen").ok, false);
  s.hero.level = 2;
  assert.equal(game.act(s, "skill", "keen").ok, true);
  assert.equal(game.stats(s, "hero").atk, 11);
  game.act(s, "enter");
  assert.equal(game.act(s, "skill", "keen").ok, false);
  game.act(s, "return");
  assert.equal(game.act(s, "skill", "keen").ok, true);
});

test("10F boss clears and unlocks 11F checkpoint marker", () => {
  const s = game.newGame();
  s.hero.level = 25;
  s.hero.hp = game.stats(s, "hero").maxHp;
  game.act(s, "enter");
  s.floor = 10;
  const result = game.act(s, "descend", null, () => 0.2);
  assert.equal(result.ok, true);
  assert.equal(s.bossCleared, true);
  assert.equal(s.maxReached, 11);
  assert.equal(s.floor, 11);
  assert.equal(game.act(s, "descend").ok, false);
});

test("Death has permanent and return-capable ally paths", () => {
  const s = game.newGame();
  const dog = s.allies[0];
  dog.dead = true;
  s.party = [];
  const ghost = {
    uid: "test-slime", id: "A02", level: 1, xp: 0, hp: 0,
    dead: true, pendingReturn: true, equipment: {}
  };
  s.allies.push(ghost);
  game.act(s, "enter");
  game.act(s, "return");
  assert.equal(dog.dead, true);
  assert.equal(ghost.dead, false);
});


test("Gacha dog gains randomized passive or fixed pursuit, based on roll", () => {
  const s = game.newGame();
  const rolls = [0.8, 0.1, 0.2];
  assert.equal(game.act(s, "pray", null, () => rolls.shift() || 0).ok, true);
  const dog = s.allies[s.allies.length - 1];
  assert.equal(dog.id, "A01");
  assert.equal(dog.ability, "硬い毛皮");
  assert.equal(game.stats(s, dog.uid).def, 2);
});
