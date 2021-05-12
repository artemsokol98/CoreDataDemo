//
//  TaskListViewController.swift
//  CoreDataDemo
//
//  Created by Alexey Efimov on 10.05.2021.
//

import UIKit
import CoreData

protocol TaskViewControllereDelegate {
    func reloadData()
}

class TaskListViewController: UITableViewController {
    
    private let context = StorageManager.shared.persistentContainer.viewContext
    private let cellID = "cell"
    private var taskList: [Task] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        setupNavigationBar()
        fetchData()
    }

    private func setupNavigationBar() {
        title = "Task List"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navBarAppearance.backgroundColor = UIColor(
            red: 21/255,
            green: 101/255,
            blue: 192/255,
            alpha: 194/255
        )
        
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTask)
        )
        
        navigationController?.navigationBar.tintColor = .white
    }
    
    private let plugIndexPath: IndexPath = IndexPath(index: 0)
    
    @objc private func addNewTask() {
        showAlert(with: "New Task", and: "What do you want to do?", and: plugIndexPath)
    }
    
    private func fetchData() {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        do {
            taskList = try context.fetch(fetchRequest)
        } catch let error {
            print(error)
        }
    }
    
    private func showAlert(with title: String, and message: String, and number: IndexPath) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let task = alert.textFields?.first?.text, !task.isEmpty else { return }
            if title == "New Task" {
                self.save(task)
            } else {
                self.update(task, indexPath: number)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextField { textField in
            if title == "New Task"{
                textField.placeholder = "New Task"
            } else {
                textField.text = self.taskList[number.row].title ?? ""
            }
        }
        present(alert, animated: true)
    }
    
    private func update(_ taskName: String, indexPath: IndexPath) {
        
        let item: Task = taskList[indexPath.row]
        item.title = taskName
        if context.hasChanges {
            do {
                try context.save()
            } catch let error {
                print(error.localizedDescription)
            }
        }
        reloadData()
    }
    
    private func save(_ taskName: String) {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Task", in: context) else { return }
        guard let task = NSManagedObject(entity: entityDescription, insertInto: context) as? Task else { return }
        task.title = taskName
        taskList.append(task)
        
        let cellIndex = IndexPath(row: taskList.count - 1, section: 0)
        tableView.insertRows(at: [cellIndex], with: .automatic)
        
        if context.hasChanges {
            do {
                try context.save()
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let task = taskList[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        cell.contentConfiguration = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let commit = taskList[indexPath.row]
            context.delete(commit)
            taskList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            do {
                try context.save()
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showAlert(with: "Update Task", and: "What do you want to do?", and: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - TaskViewControllereDelegate
extension TaskListViewController: TaskViewControllereDelegate {
    func reloadData() {
        fetchData()
        tableView.reloadData()
    }
}
