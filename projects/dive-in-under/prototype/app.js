/* Dive In Under - browser UI. Open index.html directly; no server needed. */
(function () {
  "use strict";
  const game = window.DiveCore;
  if (!game) throw Error("Missing DiveCore");
  const STORAGE_KEY = "whitespace-dive-in-under-prototype-v1";
  const ui = { selectedHuman: "hero", toastTimer: null };
  const $ = (id) => document.getElementById(id);

  function esc(value) {
    return String(value == null ? "" : value).replace(/[&<>"']/g, (m) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
    }[m]));
  }

  function load() {
    try {
      const data = JSON.parse(localStorage.getItem(STORAGE_KEY) || "null");
      if (!data || data.version !== 1 || !data.hero || !data.allies || !data.party || !data.bag || !data.stash) {
        return game.newGame();
      }
      return data;
    } catch (_err) {
      return game.newGame();
    }
  }
  let state = load();

  function save() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
      $("save-status").textContent = "保存済";
    } catch (_err) {
      $("save-status").textContent = "保存不可";
    }
  }

  function toast(message) {
    const el = $("toast");
    if (!el) return;
    el.textContent = message;
    el.classList.add("show");
    if (ui.toastTimer) clearTimeout(ui.toastTimer);
    ui.toastTimer = setTimeout(() => el.classList.remove("show"), 3000);
  }

  function btn(action, text, extra, disabled, cssClass) {
    return '<button type="button" class="btn ' + esc(cssClass || "") + '" data-action="' + esc(action) +
      '" ' + (extra || "") + (disabled ? " disabled" : "") + ">" + esc(text) + "</button>";
  }

  function itemText(item) {
    const def = game.ITEMS[item.id];
    if (!def) return "不明なアイテム";
    if (!def.slot) return def.name;
    const slot = game.SLOTS.find((entry) => entry[0] === def.slot);
    const buffs = ["atk", "def", "hp", "speed"].filter((key) => def[key]).map((key) =>
      ({ atk: "攻撃", def: "防御", hp: "最大HP", speed: "速度" }[key]) + "+" + def[key]);
    return def.name + " / " + (slot ? slot[1] : "") + " / " + buffs.join("・");
  }

  function durHtml(item) {
    if (item.dur == null) return "";
    const max = game.ITEMS[item.id].maxDur;
    return item.dur === 0
      ? '<span class="broken">破損 / 性能0</span>'
      : "耐久 " + item.dur + "/" + max;
  }

  function heroHtml() {
    const member = state.hero;
    const st = game.stats(state, "hero");
    return characterHtml("主人公", "human", member, st, true);
  }

  function characterHtml(name, kind, member, st, active) {
    const ratio = Math.max(0, Math.min(100, Math.round(100 * member.hp / st.maxHp)));
    return '<div class="char-row"><div class="char-main">' +
      '<div class="char-title"><strong>' + esc(name) + '</strong><span class="quiet">Lv.' + st.level +
      ' / ' + esc(kind) + (active ? " · 同行" : "") + "</span></div>" +
      '<div class="char-sub">HP ' + member.hp + '/' + st.maxHp + ' · 攻撃 ' + st.atk +
      ' · 防御 ' + st.def + ' · 速度 ' + st.speed + '</div>' +
      '<div class="hp-track"><div class="hp-fill ' + (ratio < 35 ? "low" : "") +
      '" style="width:' + ratio + '%"></div></div></div></div>';
  }

  function renderHeader() {
    $("deepest").textContent = "地下" + state.maxReached + "F";
    $("boss-status").textContent = state.bossCleared ? "突破済" : "未討伐";
    $("place-title").textContent = state.mode === "town" ? "地上 / 拠点" : (state.floor <= 10 ? "地下" + state.floor + "F / 潜行中" : "地下11F / 試作の終点");
    $("mode-pill").textContent = state.mode === "town" ? "準備中" : state.floor === 11 ? "10F突破" : "探索中";
    $("place-small").textContent = state.mode === "town" ? "SURFACE" : "UNDERGROUND";
    $("depth-number").textContent = state.mode === "town" ? "00" : String(state.floor).padStart(2, "0");
    $("depth-label").textContent = state.mode === "town" ? "何を持って、誰と潜るか。" :
      state.floor === 11 ? "10Fを突破した。続きは今後の開発範囲。" : "ここで潜るか、引き返すか。";
    $("primary-actions").innerHTML = state.mode === "town"
      ? btn("enter", "地下1Fへ潜る", "", false, "primary")
      : btn("descend", state.floor <= 10 ? "潜る / " + state.floor + "Fに挑む" : "11Fは未実装",
        "", state.floor > 10, "primary") + btn("return", "地上に戻る", "", false, "danger");
    $("action-hint").textContent = state.mode === "town"
      ? "出発後の装備・編成・スキル変更はできません。黄金像の祈りは出発ごとに1回。"
      : "地下では「潜る」「地上に戻る」の2択。遭遇と戦闘は自動解決。";
  }

  function renderEncounter() {
    const last = state.last || {};
    const label = { battle: "戦闘", danger: "危険", treasure: "宝", event: "イベント", info: "記録" }[last.kind] || "記録";
    $("encounter-tag").textContent = label + (last.floor ? " / " + last.floor + "F" : "");
    $("encounter-tag").className = "pill" + (last.kind === "danger" ? " warn" : "");
    $("encounter-title").textContent = last.title || "探索記録";
    $("encounter-text").textContent = last.text || "";
    $("encounter-details").innerHTML = (last.details || []).map((line) =>
      '<div class="detail-line">' + esc(line) + "</div>").join("") ||
      '<div class="empty">まだ詳細なログはありません。</div>';
    $("history").innerHTML = (state.history || []).slice(0, 16).map((line) =>
      "<li>" + esc(line) + "</li>").join("");
  }

  function renderParty() {
    $("party-summary").innerHTML = heroHtml() + '<p class="quiet">同行できる仲間：2体まで / 戦闘不能は原則永久離脱。</p>';
    $("roster").innerHTML = '<h3 class="small-heading">仲間の一覧</h3>' +
      state.allies.map((a) => {
        const def = game.ALLIES[a.id];
        const st = game.stats(state, a.uid);
        const active = state.party.includes(a.uid);
        const lost = a.dead;
        return '<div class="char-row"><div class="char-main"><div class="char-title"><strong>' +
          esc(def.name) + '</strong>' + (lost ? '<span class="broken">離脱中</span>' : "") +
          '</div><div class="char-sub">' + esc(def.kind) + ' · Lv.' + a.level + ' · ' +
          (a.ability ? esc(a.ability) : esc(def.ability)) + ' · ' +
          (def.returns ? "帰還する特性" : "永久離脱の可能性") + '</div>' +
          (lost ? "" : '<div class="char-sub">HP ' + a.hp + '/' + st.maxHp +
          ' · 攻撃 ' + st.atk + ' · 防御 ' + st.def + '</div>') + '</div>' +
          (state.mode === "town" && !lost
            ? btn("party", active ? "控えへ" : "同行", 'data-id="' + esc(a.uid) + '"',
              !active && state.party.length >= 2, "tiny")
            : active ? '<span class="quiet">同行中</span>' : "") + '</div>';
      }).join("");
  }

  function renderTown() {
    const section = $("town-panel");
    section.style.display = state.mode === "town" ? "" : "none";
    const checkpoint = '<div class="checkpoint"><span>地下1F</span><span class="mark">開始可</span></div>' +
      '<div class="checkpoint"><span>地下11F</span><span>' +
      (state.maxReached >= 11 ? "到達済 / 試作範囲外" : "未解放") + "</span></div>";
    $("town-content").innerHTML =
      '<div class="facility"><h3>黄金像</h3><p>潜行ごとに1回だけ。到達した深さに応じて報酬候補が増える。</p>' +
      btn("pray", state.prayed ? "祈り済" : "黄金像に祈る", "", state.prayed, "primary") + '</div>' +
      '<div class="facility"><h3>支給所</h3><p>支給包帯×2。自動で負傷者に使用。倉庫保存は不可。</p>' +
      '<p>現在の所持数：' + state.supplies + ' / 2</p>' +
      btn("supply", state.claimedSupply ? "支給済" : "包帯を受け取る", "", state.claimedSupply, "") + '</div>' +
      '<div class="facility"><h3>開始地点</h3>' + checkpoint + "</div>";
  }

  function renderSkills() {
    const slots = game.skillSlots(state.hero.level);
    const available = game.availableSkills(state.hero.level);
    $("skills").innerHTML = '<p class="quiet">装備中 ' + state.hero.skills.length + "/" + slots +
      ' 枠。レベルが上がると候補と枠が開く。地上で自由に変更可能。</p>' +
      Object.entries(game.SKILLS).map(([id, sk]) => {
        const owned = state.hero.skills.includes(id);
        const unlocked = available.includes(id);
        const disabled = state.mode !== "town" || !unlocked || (!owned && state.hero.skills.length >= slots);
        return '<div class="skill-row"><div><strong>' + esc(sk.name) + '</strong>' +
          '<div class="small">' + esc(sk.info) + ' · 解放Lv.' + sk.level +
          (unlocked ? "" : "（未解放）") + '</div></div>' +
          btn("skill", owned ? "解除" : "選択", 'data-id="' + esc(id) + '"', disabled, "tiny") + "</div>";
      }).join("");
  }

  function equipmentOwner() {
    if (ui.selectedHuman === "hero") return state.hero;
    const ally = game.allyById(state, ui.selectedHuman);
    if (!ally || ally.dead || game.ALLIES[ally.id].kind !== "人") {
      ui.selectedHuman = "hero";
      return state.hero;
    }
    return ally;
  }

  function renderEquipment() {
    const eligible = state.allies.filter((a) => !a.dead && game.ALLIES[a.id].kind === "人");
    const select = '<label class="quiet" for="human-target">装備する人間</label><select id="human-target"' +
      (state.mode !== "town" ? " disabled" : "") + '>' +
      '<option value="hero"' + (ui.selectedHuman === "hero" ? " selected" : "") + '>主人公</option>' +
      eligible.map((a) => '<option value="' + esc(a.uid) + '"' +
        (ui.selectedHuman === a.uid ? " selected" : "") + '>' + esc(game.ALLIES[a.id].name) +
        "</option>").join("") + "</select>";
    const owner = equipmentOwner();
    $("equipment").innerHTML = select + game.SLOTS.map(([slot, name]) => {
      const item = owner.equipment && owner.equipment[slot];
      const wear = item ? durHtml(item) : "";
      return '<div class="gear-row"><div><strong>' + esc(name) + '</strong><div class="small">' +
        (item ? esc(game.ITEMS[item.id].name) + " · " + wear : "未装備") + '</div></div>' +
        '<div class="button-stack">' +
        (item && state.mode === "town" ? btn("unequip", "外す",
          'data-target="' + esc(ui.selectedHuman) + '" data-slot="' + esc(slot) + '"', false, "tiny") +
          btn("repair", "補修",
            'data-target="' + esc(ui.selectedHuman) + '" data-slot="' + esc(slot) + '"',
            item.dur >= game.ITEMS[item.id].maxDur, "tiny") : "") +
        "</div></div>";
    }).join("");
  }

  function renderInventory() {
    function itemRow(item, inStash) {
      const def = game.ITEMS[item.id];
      const extras = def.slot ? '<span class="quiet"> · ' + durHtml(item) + '</span>' : "";
      return '<div class="item-row"><div style="min-width:0"><strong>' + esc(def.name) + '</strong>' +
        '<div class="small">' + esc(itemText(item)) + extras + '</div></div>' +
        '<div class="button-stack">' +
        (state.mode === "town" ?
          (inStash ? btn("withdraw", "引き出す", 'data-id="' + esc(item.uid) + '"', false, "tiny")
            : (def.slot ? btn("equip", "装備",
              'data-id="' + esc(item.uid) + '" data-target="' + esc(ui.selectedHuman) + '"', false, "tiny") : "") +
              btn("deposit", "預ける", 'data-id="' + esc(item.uid) + '"', false, "tiny")) : "") +
        "</div></div>";
    }
    $("inventory").innerHTML =
      '<p class="quiet">探索中の戦利品は所持品へ。包帯は支給品のためここには入りません。</p>' +
      '<h3 class="inventory-head">所持品 / ' + state.bag.length + '</h3>' +
      (state.bag.map((item) => itemRow(item, false)).join("") || '<p class="empty">所持品はありません</p>') +
      '<h3 class="inventory-head">倉庫 / ' + state.stash.length + '</h3>' +
      (state.stash.map((item) => itemRow(item, true)).join("") || '<p class="empty">倉庫は空です</p>');
  }

  function render() {
    renderHeader(); renderEncounter(); renderParty(); renderTown();
    renderSkills(); renderEquipment(); renderInventory(); save();
  }

  document.addEventListener("click", (event) => {
    const button = event.target.closest("button[data-action]");
    if (!button || button.disabled) return;
    const action = button.getAttribute("data-action");
    const arg = (action === "equip")
      ? { item: button.getAttribute("data-id"), target: button.getAttribute("data-target") }
      : (action === "repair" || action === "unequip")
        ? { target: button.getAttribute("data-target"), slot: button.getAttribute("data-slot") }
        : button.getAttribute("data-id");
    const result = game.act(state, action, arg);
    if (!result.ok) toast(result.error);
    render();
  });

  document.addEventListener("change", (event) => {
    if (event.target.id === "human-target") {
      ui.selectedHuman = event.target.value;
      render();
    }
  });

  $("reset-button").addEventListener("click", () => {
    if (!window.confirm("現在の試作セーブを初期化します。よろしいですか？")) return;
    state = game.newGame();
    ui.selectedHuman = "hero";
    render();
    toast("最初から始めました。");
  });

  render();
})();
