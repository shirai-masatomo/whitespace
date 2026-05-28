import React, { useMemo, useState } from "https://esm.sh/react@18";
import { createRoot } from "https://esm.sh/react-dom@18/client";

function App() {
  const [input, setInput] = useState("");
  const [tasks, setTasks] = useState([
    { id: 1, text: "Reactで画面を表示する", done: true },
    { id: 2, text: "新しいタスクを追加してみる", done: false },
  ]);

  const remainingCount = useMemo(
    () => tasks.filter((task) => !task.done).length,
    [tasks]
  );

  function addTask(event) {
    event.preventDefault();
    const text = input.trim();

    if (!text) {
      return;
    }

    setTasks((currentTasks) => [
      ...currentTasks,
      { id: Date.now(), text, done: false },
    ]);
    setInput("");
  }

  function toggleTask(id) {
    setTasks((currentTasks) =>
      currentTasks.map((task) =>
        task.id === id ? { ...task, done: !task.done } : task
      )
    );
  }

  return (
    React.createElement("main", { className: "app-shell" },
      React.createElement("section", { className: "card" },
        React.createElement("p", { className: "eyebrow" }, "React Practice"),
        React.createElement("h1", null, "まずは動く小さなReactアプリ"),
        React.createElement(
          "p",
          { className: "description" },
          "Node.jsなしでも、Reactの考え方を試せる最小構成です。あとからVite構成へ移しやすいよう、状態管理や描画は普通のReactで書いています。"
        ),
        React.createElement("div", { className: "status-row" },
          React.createElement("div", { className: "status-box" },
            React.createElement("span", { className: "status-label" }, "残りタスク"),
            React.createElement("strong", null, remainingCount + "件")
          ),
          React.createElement("div", { className: "status-box" },
            React.createElement("span", { className: "status-label" }, "合計"),
            React.createElement("strong", null, tasks.length + "件")
          )
        ),
        React.createElement(
          "form",
          { className: "task-form", onSubmit: addTask },
          React.createElement("input", {
            value: input,
            onChange: (event) => setInput(event.target.value),
            placeholder: "次に試したいことを書く",
            "aria-label": "新しいタスク",
          }),
          React.createElement("button", { type: "submit" }, "追加")
        ),
        React.createElement(
          "ul",
          { className: "task-list" },
          tasks.map((task) =>
            React.createElement(
              "li",
              {
                key: task.id,
                className: task.done ? "task done" : "task",
              },
              React.createElement("label", null,
                React.createElement("input", {
                  type: "checkbox",
                  checked: task.done,
                  onChange: () => toggleTask(task.id),
                }),
                React.createElement("span", null, task.text)
              )
            )
          )
        )
      )
    )
  );
}

createRoot(document.getElementById("root")).render(React.createElement(App));
