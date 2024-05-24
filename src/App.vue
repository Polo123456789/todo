<script setup lang="ts">

import { ref, onMounted, watch, computed } from 'vue';

interface Todo {
  description: string,
  done?: boolean,
  sons?: Todo[],
  referenceLink?: string | null
}

interface ReferencedTodo extends Todo {
  orignalIndex: number
}

const todos = ref<Todo[]>([]);
const dones = ref<Todo[]>([])
const dialy = ref<Todo[]>([]);
const lastDay = ref<string | null>("");

const urlParams = new URLSearchParams(window.location.search);
const dontSyncLocalStorage = urlParams.get("dontSync")
const urlTodos = urlParams.get("todos");

const resetDailys = () => {
  const today = (new Date()).toLocaleDateString();
  lastDay.value = localStorage.getItem("lastDay");
  if (lastDay.value && lastDay.value === today) {
    return;
  }
  lastDay.value = today;
  localStorage.setItem("lastDay", today);
  dialy.value.forEach((todo) => {
    todo.done = false;
  })
};

onMounted(() => {
  if (dontSyncLocalStorage) {
    if (urlTodos) {
      const data = JSON.parse(urlTodos);
      todos.value = data.todos;
      dones.value = data.dones;
      dialy.value = data.dialy;
    }
    return;
  }
  todos.value = JSON.parse(localStorage.getItem("todos") || "[]");
  dones.value = JSON.parse(localStorage.getItem("dones") || "[]");
  dialy.value = JSON.parse(localStorage.getItem("dialy") || "[]");

  watch(todos, () => {
    localStorage.setItem("todos", JSON.stringify(todos.value))
  }, { deep: true });
  
  watch(dones, () => {
    localStorage.setItem("dones", JSON.stringify(dones.value))
  }, { deep: true });
  
  watch(dialy, () => {
    localStorage.setItem("dialy", JSON.stringify(dialy.value))
  }, { deep: true });

  resetDailys()
});

const dialyDones = computed(() => {
  const dones: ReferencedTodo[] = [];
  dialy.value.forEach((todo, index) => {
    if (todo.done) {
      dones.push({
        ...todo,
        orignalIndex: index
      })
    }
  });
  return dones;
});

const dialyPendings = computed(() => {
  const pendings: ReferencedTodo[] = [];
  dialy.value.forEach((todo, index) => {
    if (!todo.done) {
      pendings.push({
        ...todo,
        orignalIndex: index,
      });
    }
  });
  return pendings;
})

const exportData = (clipboard?: boolean) => {
  const data = {
    todos: todos.value,
    dones: dones.value,
    dialy: dialy.value
  }
  const json = JSON.stringify(data);
  if (clipboard) {
    window.navigator.clipboard.writeText(json);
    alert("Copiado al portapapeles")
  }
  return json;
}

const importData = () => {
  let json = prompt("Ingrese el json ('clear' para borrar):");
  if (!json) {
    return
  }
  if (json === 'clear') {
    json = '{"todos":[],"dones": [],"dialy":[]}';
  }
  const data = JSON.parse(json);
  todos.value = data.todos;
  dones.value = data.dones;
  dialy.value = data.dialy;
}

const newTodoDesciption = ref("");
const newTodoDialy = ref(false)

const addTodo = (shiftModifier?: boolean) => {
  if (!newTodoDesciption.value) {
    return;
  }
  const todo: Todo = {
    description: newTodoDesciption.value
  }
  if (newTodoDialy.value) {
    if (shiftModifier) {
      dialy.value.push(todo)
    } else {
      dialy.value.unshift(todo)
    }
  } else {
    if (shiftModifier) {
      todos.value.push(todo)
    } else {
      todos.value.unshift(todo)
    }
  }
  newTodoDesciption.value = "";
  newTodoDialy.value = false;
}

const addChildrenTo = (i: number) => {
  const child = prompt("Cual es la subtarea?");
  if (child) {
    todos.value[i].sons = todos.value[i].sons || [];
    todos.value[i].sons?.push({
      description: child
    })
  }
}

const addReferenceLink = (todo: Todo) => {
  const link = prompt("Cual es el link?");
  todo.referenceLink = link;
}

const followReferenceLink = (todo: Todo) => {
  if (todo.referenceLink) {
    window.open(todo.referenceLink, "_blank");
  } else {
    alert("No hay un link relacionado, agregelo o editelo usando el clic derecho.");
  }
}

</script>

<template>
  <div class="d-flex gap-3 mt-3">
    <button class="btn btn-dark" @mousedown="importData()">Importar</button>
    <button class="btn btn-dark" @mousedown="exportData(true)">Exportar</button>
  </div>
  <div class="d-flex gap-3 mt-3 align-items-center">
    <input type="text" v-model="newTodoDesciption" class="form-control" placeholder="Descripcion"
      @keyup.enter.exact="addTodo()" @keyup.shift.enter.exact="addTodo(true)">
    <div class="form-check">
      <input type="checkbox" v-model="newTodoDialy" class="form-check-input">
      <label class="form-check-label">Diario</label>
    </div>
    <button class="btn btn-dark" @mousedown.exact="addTodo()" @mousedown.shift.exact="addTodo(true)">Agregar</button>
  </div>

  <div class="row">
    <div v-if="todos.length != 0" class="col">
      <h1 class="mt-3">Pendientes</h1>
      <ul class="list-group">
        <li class="list-group-item" v-for="todo, i of todos" :key="i">
          <div class="d-flex gap-1 align-items-center">
            {{ todo.description }}
            <button class="btn btn-success ms-auto" @mousedown="dones.push(todos.splice(i, 1)[0])" title="Completar">
              <i class="bi bi-check2"></i>
            </button>
            <button class="btn btn-dark" @mousedown="addChildrenTo(i)" title="Agregar Hijos">
              <i class="bi bi-diagram-3-fill"></i>
            </button>
            <button class="btn btn-primary" @mousedown="todos.unshift(todos.splice(i, 1)[0])" title="Maxima Prioridad">
              <i class="bi bi-chevron-double-up"></i>
            </button>
            <button class="btn btn-secondary" @mousedown.right.prevent="addReferenceLink(todo)" @mousedown.left="followReferenceLink(todo)" :title="todo.referenceLink ? todo.referenceLink : undefined">
              <i class="bi bi-link-45deg"></i>
            </button>
            <button class="btn btn-danger" @mousedown="todos.splice(i, 1)" title="Eliminar">
              <i class="bi bi-x-octagon"></i>
            </button>
          </div>
          <h6 class="mt-2" v-if="todo.sons && todo.sons.length != 0">Sub Tareas:</h6>
          <ul class="list-group">
            <li class="list-group-item" v-for="son, i of todo.sons" :key="i">
              <div class="form-check d-flex gap-3 align-items-center">
                <input type="checkbox" v-model="son.done">
                <label @mousedown.right.prevent="addReferenceLink(son)" >{{ son.description }}</label>
                <button v-if="son.referenceLink" class="badge bg-secondary ms-auto" @mousedown="followReferenceLink(son)" @mousedown.right.prevent="addReferenceLink(son)" :title="todo.referenceLink ? todo.referenceLink : undefined">
                  <i class="bi bi-link-45deg"></i>
                </button>
              </div>
            </li>
          </ul>
        </li>
      </ul>
    </div>

    <div v-if="dialy.length != 0" class="col">
      <h1 class="mt-3">Diarios</h1>
      <ul class="list-group">
        <li class="list-group-item d-flex gap-1 align-items-center" v-for="todo, i of dialyPendings" :key="i">
          <span @mousedown.right.prevent="addReferenceLink(dialy[todo.orignalIndex])">
            {{ todo.description }}
          </span>
          <div class="ms-auto"></div>
          <button v-if="todo.referenceLink" class="btn btn-secondary" @mousedown.left="followReferenceLink(todo)" @mousedown.right.prevent="addReferenceLink(dialy[todo.orignalIndex])" :title="todo.referenceLink ? todo.referenceLink : undefined">
            <i class="bi bi-link-45deg"></i>
          </button>
          <button class="btn btn-success" @mousedown="dialy[todo.orignalIndex].done = true">
            <i class="bi bi-check2"></i>
          </button>
          <button class="btn btn-danger" @mousedown="dialy.splice(todo.orignalIndex, 1)">
            <i class="bi bi-x-octagon"></i>
          </button>
        </li>
        <li class="list-group-item d-flex align-items-center" v-for="done, i of dialyDones" :key="i">
          <span class="text-muted text-decoration-line-through">
            {{ done.description }}
          </span>
          <button class="btn btn-secondary ms-auto" @mousedown="dialy[done.orignalIndex].done = false">
            <i class="bi bi-journal-x"></i>
          </button>
        </li>
      </ul>
    </div>

  </div>

  <div v-if="dones.length != 0">
    <h1 class="mt-3">Terminados</h1>
    <ul class="list-group">
      <li class="list-group-item d-flex gap-1 align-items-center" v-for="done, i of dones" :key="i">
        {{ done.description }}
        <button class="btn btn-secondary ms-auto" @mousedown="todos.push(dones.splice(i, 1)[0])" title="Restaurar">
          <i class="bi bi-journal-x"></i>
        </button>
        <button class="btn btn-danger" @mousedown="dones.splice(i, 1)" title="Borrar">
          <i class="bi bi-x-octagon"></i>
        </button>
      </li>
    </ul>
  </div>
</template>

<style scoped>
.form-check > button {
	height: 2rem;
	width: 2rem;
}
</style>
