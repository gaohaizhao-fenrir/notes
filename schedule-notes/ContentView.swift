//
//  ContentView.swift
//  schedule-notes
//
//  Created by gaohaizhao on 2026/3/18.
//

import SwiftUI

struct ContentView: View {
    struct TaskItem: Identifiable {
        let id = UUID()
        var title: String
    }

    @State private var tasks: [TaskItem] = [
        TaskItem(title: "买牛奶"),
        TaskItem(title: "整理会议纪要")
    ]
    @State private var newTaskTitle: String = ""
    @State private var editingTaskID: TaskItem.ID?
    @State private var editingTitle: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    TextField("输入新的 task", text: $newTaskTitle)
                        .textFieldStyle(.roundedBorder)

                    Button("添加") {
                        addTask()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)

                List {
                    ForEach($tasks) { $task in
                        HStack(spacing: 10) {
                            if editingTaskID == task.id {
                                TextField("编辑 task", text: $editingTitle)
                                    .textFieldStyle(.roundedBorder)

                                Button("保存") {
                                    saveEdit(for: task.id)
                                }
                                .buttonStyle(.bordered)
                            } else {
                                Text(task.title)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button("修改") {
                                    startEdit(for: task)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteTask)
                }
                .listStyle(.plain)
            }
            .navigationTitle("记事列表")
        }
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        tasks.append(TaskItem(title: title))
        newTaskTitle = ""
    }

    private func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }

    private func startEdit(for task: TaskItem) {
        editingTaskID = task.id
        editingTitle = task.title
    }

    private func saveEdit(for id: TaskItem.ID) {
        let title = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].title = title
        editingTaskID = nil
        editingTitle = ""
    }
}

#Preview {
    ContentView()
}
