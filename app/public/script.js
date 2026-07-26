const countEl = document.getElementById("count");
const statusEl = document.getElementById("status");

async function loadCount() {
  try {
    const res = await fetch("/api/count");
    const data = await res.json();
    countEl.textContent = data.value;
    statusEl.textContent = "synced with database";
  } catch (e) {
    statusEl.textContent = "unable to reach API";
  }
}

async function post(path) {
  try {
    const res = await fetch(path, { method: "POST" });
    const data = await res.json();
    countEl.textContent = data.value;
    statusEl.textContent = "synced with database";
  } catch (e) {
    statusEl.textContent = "unable to reach API";
  }
}

document.getElementById("increment").addEventListener("click", () => post("/api/increment"));
document.getElementById("decrement").addEventListener("click", () => post("/api/decrement"));

loadCount();
