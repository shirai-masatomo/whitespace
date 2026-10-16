/* Dive In Under - offline 10F rules prototype. No external dependencies. */
(function (root) {
  "use strict";

  const SLOTS = [
    ["head", "頭"], ["upper", "上半身"], ["lower", "下半身"], ["feet", "足"],
    ["neck", "首"], ["ears", "耳"], ["eyes", "目"], ["finger", "指"], ["arms", "腕"]
  ];

  const ITEMS = {
    I01: { name: "皮の帽子", slot: "head", def: 1, maxDur: 10, tier: 1 },
    I02: { name: "粗布の上着", slot: "upper", def: 2, maxDur: 12, tier: 1 },
    I03: { name: "革のズボン", slot: "lower", def: 1, maxDur: 10, tier: 1 },
    I04: { name: "古いブーツ", slot: "feet", def: 1, maxDur: 9, tier: 1 },
    I05: { name: "鉄の指輪", slot: "finger", atk: 2, maxDur: 10, tier: 1 },
    I06: { name: "守りの腕輪", slot: "arms", def: 2, maxDur: 10, tier: 1 },
    I07: { name: "煤けた首飾り", slot: "neck", hp: 5, maxDur: 9, tier: 2 },
    I08: { name: "火花の耳飾り", slot: "ears", speed: 2, maxDur: 10, tier: 2 },
    I09: { name: "透視レンズ", slot: "eyes", atk: 1, maxDur: 10, tier: 2 },
    I10: { name: "補修石", kind: "material", tier: 1 },
    I11: { name: "深層の指輪", slot: "finger", atk: 4, maxDur: 15, tier: 3 }
  };

  const ALLIES = {
    A01: { name: "洞穴犬", kind: "動物", hp: 18, atk: 4, def: 0, speed: 7, ability: "追撃", returns: false },
    A02: { name: "灯りスライム", kind: "魔物", hp: 16, atk: 3, def: 1, speed: 3, ability: "灯の癒し", returns: true },
    A03: { name: "迷いの坑夫", kind: "人", hp: 22, atk: 5, def: 1, speed: 4, ability: "踏ん張り", returns: false }
  };

  const ENEMIES = {
    E01: { name: "地底ネズミ", hp: 8, atk: 3, def: 0, speed: 6, exp: 4, min: 1 },
    E02: { name: "粘菌スライム", hp: 11, atk: 3, def: 1, speed: 2, exp: 5, min: 1 },
    E03: { name: "鉄羽コウモリ", hp: 13, atk: 5, def: 0, speed: 8, exp: 7, min: 3 },
    E04: { name: "坑道ゴブリン", hp: 18, atk: 6, def: 1, speed: 5, exp: 9, min: 4 },
    E05: { name: "岩甲虫", hp: 24, atk: 7, def: 3, speed: 2, exp: 12, min: 7 },
    B10: { name: "門番の石像", hp: 42, atk: 8, def: 2, speed: 3, exp: 26, min: 10 }
  };

  const EVENTS = {
    EV01: "地下の湧き水", EV02: "崩れた足場", EV03: "迷子の坑夫",
    EV04: "古い標識", EV05: "祈祷の残光"
  };

  const SKILLS = {
    keen: { name: "鋭い勘", level: 2, info: "攻撃+2", atk: 2 },
    vigor: { name: "強靭", level: 2, info: "最大HP+6", hp: 6 },
    guard: { name: "堅守", level: 3, info: "防御+2", def: 2 },
    quick: { name: "俊足", level: 4, info: "速度+3", speed: 3 }
  };

  const FLOOR_POOLS = {
    1: { enemy: ["E01", "E02"], event: ["EV01", "EV04"], item: ["I01", "I02"] },
    2: { enemy: ["E01", "E02"], event: ["EV01", "EV02"], item: ["I04", "I10"] },
    3: { enemy: ["E01", "E02", "E03"], event: ["EV02", "EV04"], item: ["I01", "I04"] },
    4: { enemy: ["E02", "E03", "E04"], event: ["EV01", "EV03"], item: ["I03", "I05"] },
    5: { enemy: ["E02", "E03", "E04"], event: ["EV02", "EV03"], item: ["I06", "I10"] },
    6: { enemy: ["E02", "E03", "E04"], event: ["EV01", "EV03"], item: ["I05", "I06", "I10"] },
    7: { enemy: ["E03", "E04", "E05"], event: ["EV02", "EV05"], item: ["I06", "I07"] },
    8: { enemy: ["E03", "E04", "E05"], event: ["EV01", "EV05"], item: ["I07", "I08", "I11"] },
    9: { enemy: ["E04", "E05"], event: ["EV02", "EV05"], item: ["I09", "I10", "I11"] }
  };

  function choose(list, rng) {
    return list[Math.min(list.length - 1, Math.floor(rng() * list.length))];
  }

  function log(s, message) {
    s.history.unshift(message);
    s.history = s.history.slice(0, 80);
  }

  function makeItem(s, id) {
    const item = ITEMS[id];
    if (!item) throw Error("Unknown item: " + id);
    return { uid: "i" + s.nextId++, id: id, dur: item.maxDur == null ? null : item.maxDur };
  }

  function makeAlly(s, id) {
    const def = ALLIES[id];
    if (!def) throw Error("Unknown ally: " + id);
    return {
      uid: "a" + s.nextId++, id: id, level: 1, xp: 0, hp: def.hp,
      dead: false, pendingReturn: false, equipment: {}
    };
  }

  function newGame() {
    const s = {
      version: 1, nextId: 1, mode: "town", floor: 0, maxReached: 1,
      bossCleared: false, selectedStart: 1,
      hero: { level: 1, xp: 0, hp: 26, skills: [], equipment: {} },
      allies: [], party: [], bag: [], stash: [], supplies: 0,
      claimedSupply: false, prayed: false, flags: {},
      history: [], last: { kind: "info", title: "探索の準備", text: "支給所と黄金像で準備してから地下へ潜ろう。", details: [] }
    };
    s.hero.equipment.upper = makeItem(s, "I02");
    s.hero.equipment.finger = makeItem(s, "I05");
    const dog = makeAlly(s, "A01");
    s.allies.push(dog);
    s.party.push(dog.uid);
    log(s, "地下1Fの探索を開始できる。初期仲間: 洞穴犬。");
    return s;
  }

  function allyById(s, uid) {
    return s.allies.find((a) => a.uid === uid);
  }

  function character(s, uid) {
    if (uid === "hero") return s.hero;
    const ally = allyById(s, uid);
    if (ally && ALLIES[ally.id].kind === "人" && !ally.dead) return ally;
    return null;
  }

  function availableSkills(level) {
    return Object.entries(SKILLS).filter((entry) => entry[1].level <= level).map((entry) => entry[0]);
  }

  function skillSlots(level) {
    return Math.min(3, Math.max(0, level - 1));
  }

  function equippedBonus(equipment, stat) {
    let total = 0;
    Object.values(equipment || {}).forEach((item) => {
      if (!item || item.dur <= 0) return;
      const def = ITEMS[item.id];
      if (!def || !def[stat]) return;
      total += Math.round(def[stat] * item.dur / def.maxDur);
    });
    return total;
  }

  function stats(s, uid) {
    let base, level, skills = [], equipment = {};
    if (uid === "hero") {
      base = { name: "主人公", hp: 26, atk: 6, def: 1, speed: 5 };
      level = s.hero.level;
      skills = s.hero.skills;
      equipment = s.hero.equipment;
    } else {
      const a = allyById(s, uid);
      if (!a) return null;
      base = ALLIES[a.id];
      level = a.level;
      equipment = a.equipment || {};
    }
    const passive = (stat) => skills.reduce((sum, id) => sum + (SKILLS[id] && SKILLS[id][stat] || 0), 0);
    return {
      name: base.name, level: level,
      maxHp: base.hp + (level - 1) * 3 + passive("hp") + equippedBonus(equipment, "hp"),
      atk: base.atk + (level - 1) + passive("atk") + equippedBonus(equipment, "atk"),
      def: base.def + Math.floor((level - 1) / 2) + passive("def") + equippedBonus(equipment, "def"),
      speed: base.speed + passive("speed") + equippedBonus(equipment, "speed")
    };
  }

  function partyMembers(s) {
    const members = [{ uid: "hero", character: s.hero, name: "主人公" }];
    s.party.forEach((uid) => {
      const a = allyById(s, uid);
      if (a && !a.dead) members.push({ uid: uid, character: a, name: ALLIES[a.id].name });
    });
    return members;
  }

  function levelUp(s, c, uid, exp, details) {
    c.xp += exp;
    let nextExp = c.level * (uid === "hero" ? 12 : 10);
    while (c.xp >= nextExp && c.level < 30) {
      c.xp -= nextExp;
      c.level++;
      const maxHp = stats(s, uid).maxHp;
      c.hp = Math.min(maxHp, c.hp + 3);
      details.push(stats(s, uid).name + "がLv." + c.level + "に成長！");
      if (uid === "hero") details.push("地上で主人公のスキルを再設定できます。");
      nextExp = c.level * (uid === "hero" ? 12 : 10);
    }
  }

  function wearEquipment(s) {
    [s.hero].concat(s.allies.filter((a) => s.party.includes(a.uid) && ALLIES[a.id].kind === "人"))
      .forEach((c) => {
        Object.values(c.equipment || {}).forEach((item) => {
          if (item && item.dur != null && item.dur > 0) item.dur--;
        });
      });
    partyMembers(s).forEach((m) => { m.character.hp = Math.min(m.character.hp, stats(s, m.uid).maxHp); });
  }

  function applyDeaths(s, details) {
    s.allies.forEach((a) => {
      if (!s.party.includes(a.uid) || a.hp > 0 || a.dead) return;
      a.dead = true;
      a.pendingReturn = !!ALLIES[a.id].returns;
      s.party = s.party.filter((id) => id !== a.uid);
      details.push(ALLIES[a.id].name + (a.pendingReturn ? "は消えた。帰還時に戻ってくる。" : "が死亡した。永久離脱。"));
    });
  }

  function autoSupplies(s, details) {
    while (s.supplies > 0) {
      const hurt = partyMembers(s).filter((m) => m.character.hp > 0 && m.character.hp / stats(s, m.uid).maxHp < 0.6)
        .sort((a, b) => a.character.hp / stats(s, a.uid).maxHp - b.character.hp / stats(s, b.uid).maxHp);
      if (!hurt.length) break;
      const m = hurt[0];
      const amount = Math.min(8, stats(s, m.uid).maxHp - m.character.hp);
      m.character.hp += amount;
      s.supplies--;
      details.push("支給包帯: " + m.name + "のHPが" + amount + "回復（残" + s.supplies + "）。");
    }
  }

  function battle(s, floor, enemyId, rng) {
    const def = ENEMIES[enemyId];
    const extra = Math.max(0, floor - def.min);
    const foe = {
      name: def.name, hp: def.hp + extra,
      atk: def.atk + Math.floor(extra / 3),
      def: def.def, speed: def.speed, exp: def.exp + floor
    };
    const details = [];
    let defeated = false;
    let rounds = 0;
    for (let round = 1; round <= 30; round++) {
      rounds = round;
      const actors = partyMembers(s).filter((m) => m.character.hp > 0)
        .map((m) => ({ kind: "party", uid: m.uid, score: stats(s, m.uid).speed + rng() * 0.01 }));
      if (foe.hp > 0) actors.push({ kind: "enemy", score: foe.speed + rng() * 0.01 });
      actors.sort((a, b) => b.score - a.score);
      for (const actor of actors) {
        if (foe.hp <= 0 || s.hero.hp <= 0) break;
        if (actor.kind === "enemy") {
          const targets = partyMembers(s).filter((m) => m.character.hp > 0);
          if (!targets.length) break;
          const target = choose(targets, rng);
          const stat = stats(s, target.uid);
          const reducedAtk = target.uid !== "hero" && allyById(s, target.uid).id === "A03" ? 1 : 0;
          const damage = Math.max(1, foe.atk + (enemyId === "B10" && round % 3 === 0 ? 2 : 0) -
            stat.def - reducedAtk + Math.floor(rng() * 3) - 1);
          target.character.hp = Math.max(0, target.character.hp - damage);
          details.push("R" + round + " " + foe.name + " → " + stat.name + " " + damage + "ダメージ");
        } else {
          const m = partyMembers(s).find((v) => v.uid === actor.uid && v.character.hp > 0);
          if (!m) continue;
          const a = m.uid === "hero" ? null : allyById(s, m.uid);
          if (a && a.id === "A02" && rng() < 0.35) {
            const candidates = partyMembers(s).filter((v) => v.character.hp > 0 && v.character.hp < stats(s, v.uid).maxHp);
            if (candidates.length) {
              candidates.sort((x, y) => x.character.hp / stats(s, x.uid).maxHp - y.character.hp / stats(s, y.uid).maxHp);
              const healed = candidates[0];
              const amount = Math.min(4, stats(s, healed.uid).maxHp - healed.character.hp);
              healed.character.hp += amount;
              details.push("R" + round + " 灯の癒し → " + healed.name + " HP+" + amount);
              continue;
            }
          }
          const stat = stats(s, m.uid);
          const damage = Math.max(1, stat.atk - foe.def + Math.floor(rng() * 3) - 1);
          foe.hp = Math.max(0, foe.hp - damage);
          details.push("R" + round + " " + stat.name + " → " + foe.name + " " + damage + "ダメージ");
          if (a && a.id === "A01" && foe.hp > 0 && rng() < 0.25) {
            foe.hp = Math.max(0, foe.hp - 2);
            details.push("　洞穴犬の追撃！ 2ダメージ");
          }
        }
      }
      if (foe.hp <= 0 || s.hero.hp <= 0) break;
    }

    wearEquipment(s);
    applyDeaths(s, details);
    if (foe.hp <= 0 && s.hero.hp > 0) {
      defeated = true;
      const survivors = partyMembers(s).filter((m) => m.character.hp > 0);
      survivors.forEach((m) => levelUp(s, m.character, m.uid, foe.exp, details));
      autoSupplies(s, details);
      details.push(foe.name + "を撃破。EXP +" + foe.exp + " / 生存者。");
    } else {
      details.push(s.hero.hp <= 0 ? "主人公が倒れた。試作ルールでは強制帰還。" : "戦闘が長引いたため撤退。");
    }
    return { win: defeated, title: def.name, rounds: rounds, details: details };
  }

  function shrinePool(s) {
    if (s.maxReached >= 11) return ["I06", "I07", "I08", "I09", "I11"];
    if (s.maxReached >= 6) return ["I03", "I05", "I06", "I07"];
    return ["I01", "I04", "I05"];
  }

  function backToTown(s, failed, reason) {
    if (s.mode === "town") return;
    s.mode = "town";
    s.floor = 0;
    s.supplies = 0;
    s.claimedSupply = false;
    s.prayed = false;
    s.hero.hp = stats(s, "hero").maxHp;
    s.allies.forEach((a) => {
      if (a.pendingReturn) {
        a.dead = false;
        a.pendingReturn = false;
        log(s, ALLIES[a.id].name + "が地上で戻ってきた。");
      }
      if (!a.dead) a.hp = stats(s, a.uid).maxHp;
    });
    log(s, failed ? "探索失敗。地上へ帰還した。" : "地上へ帰還した。");
    if (!reason) {
      s.last = { kind: failed ? "danger" : "info", title: failed ? "探索失敗" : "帰還",
        text: "地上に戻った。獲得品は所持品に残り、支給包帯は失効した。", details: [] };
    }
  }

  function resolveEvent(s, floor, rng) {
    let choices = FLOOR_POOLS[floor].event.filter((id) => id !== "EV03" || !s.flags.minerFound);
    if (!choices.length) choices = ["EV01"];
    const id = choose(choices, rng);
    const details = [];
    if (id === "EV01") {
      partyMembers(s).forEach((m) => {
        if (m.character.hp > 0) m.character.hp = Math.min(stats(s, m.uid).maxHp, m.character.hp + 6);
      });
      details.push("生存中の仲間全員のHPが6回復。");
    } else if (id === "EV02") {
      s.hero.hp = Math.max(0, s.hero.hp - 3);
      details.push("落石で主人公のHPが3減少。");
    } else if (id === "EV03") {
      s.flags.minerFound = true;
      const ally = makeAlly(s, "A03");
      s.allies.push(ally);
      if (s.party.length < 2) s.party.push(ally.uid);
      details.push("迷いの坑夫が仲間になった！ 人間なので装備可能。");
    } else if (id === "EV04") {
      levelUp(s, s.hero, "hero", 4, details);
      details.push("古い標識から経験値を4得た。");
    } else if (id === "EV05") {
      s.bag.push(makeItem(s, "I10"));
      details.push("補修石をひとつ入手。");
    }
    s.last = { kind: "event", floor: floor, title: EVENTS[id], text: "地下" + floor + "F：イベント", details: details };
    log(s, floor + "F イベント: " + EVENTS[id]);
    if (s.hero.hp <= 0) {
      backToTown(s, true, "event");
      s.last.details.push("主人公が倒れたため強制帰還した。");
      return false;
    }
    return true;
  }

  function resolveFloor(s, rng) {
    const floor = s.floor;
    if (floor > 10) return "10Fの先はまだ未実装です。";
    const boss = floor === 10;
    const weights = floor <= 3 ? [70, 20, 10] : floor <= 6 ? [75, 15, 10] : [80, 10, 10];
    const rolled = Math.floor(rng() * 100);
    const type = boss || rolled < weights[0] ? "battle" :
      rolled < weights[0] + weights[1] ? "treasure" : "event";
    let success = true;
    if (type === "battle") {
      const id = boss ? "B10" : choose(FLOOR_POOLS[floor].enemy, rng);
      const outcome = battle(s, floor, id, rng);
      s.last = {
        kind: outcome.win ? "battle" : "danger", floor: floor,
        title: boss ? "10Fボス: " + outcome.title : "戦闘: " + outcome.title,
        text: outcome.win ? outcome.rounds + "ラウンドで勝利。" : "戦闘に敗北した。",
        details: outcome.details
      };
      log(s, floor + "F " + (outcome.win ? "撃破: " : "敗北: ") + outcome.title);
      if (!outcome.win) {
        success = false;
        backToTown(s, true, "battle");
      }
    } else if (type === "treasure") {
      const id = choose(FLOOR_POOLS[floor].item, rng);
      const item = makeItem(s, id);
      s.bag.push(item);
      s.last = { kind: "treasure", floor: floor, title: "宝箱", text: "地下" + floor + "Fで" + ITEMS[id].name + "を入手。", details: [] };
      log(s, floor + "F 宝箱: " + ITEMS[id].name);
    } else {
      success = resolveEvent(s, floor, rng);
    }

    if (success) {
      s.floor++;
      s.maxReached = Math.max(s.maxReached, s.floor);
      if (boss) {
        s.bossCleared = true;
        log(s, "10Fの門番を突破！ 11Fに到達した。11Fは試作範囲外。");
        s.last.details.push("10F突破！ 11Fの開始地点が解放された（11Fは未実装）。");
      }
    }
    return null;
  }

  function act(s, action, arg, rng) {
    rng = rng || Math.random;
    function townOnly() { return s.mode === "town" ? null : "この操作は地上でのみ可能です。"; }
    let err = null;
    if (action === "pray") {
      err = townOnly();
      if (!err && s.prayed) err = "この探索分はすでに祈りました。";
      if (!err) {
        let reward, summary, roll = rng();
        if (roll < 0.45) {
          const id = choose(shrinePool(s), rng);
          reward = makeItem(s, id); s.bag.push(reward);
          summary = ITEMS[id].name + "（装備）";
        } else if (roll < 0.70) {
          reward = makeItem(s, "I10"); s.bag.push(reward);
          summary = "補修石（アイテム）";
        } else {
          const id = choose(["A01", "A02"], rng);
          const ally = makeAlly(s, id); s.allies.push(ally);
          if (s.party.length < 2) s.party.push(ally.uid);
          summary = ALLIES[id].name + "（仲間）";
        }
        s.prayed = true;
        s.last = { kind: "treasure", title: "黄金像の祈り", text: "祈りに応えて " + summary + " を授かった。", details: [] };
        log(s, "黄金像: " + summary);
      }
    } else if (action === "supply") {
      err = townOnly();
      if (!err && s.claimedSupply) err = "この探索分の支給は受取済みです。";
      if (!err) {
        s.supplies = 2; s.claimedSupply = true;
        log(s, "支給所から包帯2つを受け取った（倉庫保存不可）。");
      }
    } else if (action === "enter") {
      err = townOnly();
      if (!err) {
        s.mode = "dungeon";
        s.floor = 1;
        s.maxReached = Math.max(s.maxReached, 1);
        s.prayed = false;
        log(s, "1Fから潜行開始。探索準備は出発時に確定。");
        s.last = { kind: "info", title: "潜行開始", text: "地下1Fから開始。準備が整ったら『潜る』を選択。", details: [] };
      }
    } else if (action === "descend") {
      if (s.mode !== "dungeon") err = "地上では潜る操作ができません。";
      else err = resolveFloor(s, rng);
    } else if (action === "return") {
      if (s.mode !== "dungeon") err = "すでに地上です。";
      else backToTown(s, false, null);
    } else if (action === "deposit" || action === "withdraw") {
      err = townOnly();
      if (!err) {
        const from = action === "deposit" ? s.bag : s.stash;
        const to = action === "deposit" ? s.stash : s.bag;
        const index = from.findIndex((i) => i.uid === arg);
        if (index < 0) err = "対象のアイテムが見つかりません。";
        else to.push(from.splice(index, 1)[0]);
      }
    } else if (action === "equip") {
      err = townOnly();
      const target = character(s, arg && arg.target);
      if (!err && !target) err = "人間の装備対象を選んでください。";
      const index = s.bag.findIndex((i) => i.uid === (arg && arg.item));
      if (!err && (index < 0 || !ITEMS[s.bag[index].id].slot)) err = "装備できません。";
      if (!err) {
        const item = s.bag.splice(index, 1)[0];
        const slot = ITEMS[item.id].slot;
        const old = target.equipment[slot];
        if (old) s.bag.push(old);
        target.equipment[slot] = item;
        target.hp = Math.min(target.hp, stats(s, arg.target).maxHp);
      }
    } else if (action === "unequip" || action === "repair") {
      err = townOnly();
      const target = character(s, arg && arg.target);
      if (!err && !target) err = "人間の装備対象を選んでください。";
      const item = target && target.equipment[arg && arg.slot];
      if (!err && !item) err = "対象部位に装備がありません。";
      if (!err && action === "unequip") {
        s.bag.push(item);
        delete target.equipment[arg.slot];
        target.hp = Math.min(target.hp, stats(s, arg.target).maxHp);
      } else if (!err && action === "repair") {
        const stone = s.bag.findIndex((i) => i.id === "I10");
        if (stone < 0) err = "修理には補修石が必要です。";
        else if (item.dur >= ITEMS[item.id].maxDur) err = "耐久値は最大です。";
        else {
          s.bag.splice(stone, 1);
          item.dur = ITEMS[item.id].maxDur;
          log(s, ITEMS[item.id].name + "を補修した。");
        }
      }
    } else if (action === "party") {
      err = townOnly();
      const ally = allyById(s, arg);
      if (!err && (!ally || ally.dead)) err = "その仲間は編成できません。";
      if (!err) {
        if (s.party.includes(arg)) s.party = s.party.filter((uid) => uid !== arg);
        else if (s.party.length >= 2) err = "同行できる仲間は2体までです。";
        else s.party.push(arg);
      }
    } else if (action === "skill") {
      err = townOnly();
      if (!err && (!SKILLS[arg] || SKILLS[arg].level > s.hero.level)) err = "未解放のスキルです。";
      if (!err) {
        if (s.hero.skills.includes(arg)) s.hero.skills = s.hero.skills.filter((id) => id !== arg);
        else if (s.hero.skills.length >= skillSlots(s.hero.level)) err = "スキル枠が足りません。";
        else s.hero.skills.push(arg);
        s.hero.hp = Math.min(s.hero.hp, stats(s, "hero").maxHp);
      }
    } else {
      err = "未知の操作です。";
    }
    return { ok: !err, error: err };
  }

  const api = {
    SLOTS: SLOTS, ITEMS: ITEMS, ALLIES: ALLIES, ENEMIES: ENEMIES,
    EVENTS: EVENTS, SKILLS: SKILLS, FLOOR_POOLS: FLOOR_POOLS,
    newGame: newGame, act: act, stats: stats, availableSkills: availableSkills,
    skillSlots: skillSlots, partyMembers: partyMembers, allyById: allyById
  };
  root.DiveCore = api;
  if (typeof module !== "undefined" && module.exports) module.exports = api;
})(typeof window !== "undefined" ? window : globalThis);
