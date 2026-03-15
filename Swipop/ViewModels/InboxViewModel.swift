//
//  InboxViewModel.swift
//  Swipop
//

import ClerkKit
import Foundation

@MainActor
@Observable
final class InboxViewModel {
    private(set) var activities: [Activity] = []
    private(set) var isLoading = false

    var hasUnread: Bool {
        activities.contains { !$0.isRead }
    }

    var unreadCount: Int {
        activities.filter { !$0.isRead }.count
    }

    var groupedActivities: [ActivityGroup] {
        let calendar = Calendar.current
        let now = Date()

        var today: [Activity] = []
        var yesterday: [Activity] = []
        var thisWeek: [Activity] = []
        var earlier: [Activity] = []

        for activity in activities {
            if calendar.isDateInToday(activity.createdAt) {
                today.append(activity)
            } else if calendar.isDateInYesterday(activity.createdAt) {
                yesterday.append(activity)
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
                activity.createdAt > weekAgo
            {
                thisWeek.append(activity)
            } else {
                earlier.append(activity)
            }
        }

        var groups: [ActivityGroup] = []
        if !today.isEmpty { groups.append(ActivityGroup(title: "Today", activities: today)) }
        if !yesterday.isEmpty { groups.append(ActivityGroup(title: "Yesterday", activities: yesterday)) }
        if !thisWeek.isEmpty { groups.append(ActivityGroup(title: "This Week", activities: thisWeek)) }
        if !earlier.isEmpty { groups.append(ActivityGroup(title: "Earlier", activities: earlier)) }

        return groups
    }

    private let service = ActivityService.shared

    func loadActivities() async {
        guard Clerk.shared.user != nil else {
            activities = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            activities = try await service.fetchActivities()
        } catch {
            print("Failed to load activities: \(error)")
        }
    }

    func markAsRead(_ activity: Activity) async {
        guard !activity.isRead else { return }

        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            activities[index].isRead = true
        }

        do {
            try await service.markAsRead(activityId: activity.id)
        } catch {
            print("Failed to mark as read: \(error)")
        }
    }

    func markAllAsRead() async {
        guard Clerk.shared.user != nil else { return }

        for index in activities.indices {
            activities[index].isRead = true
        }

        do {
            try await service.markAllAsRead()
        } catch {
            print("Failed to mark all as read: \(error)")
        }
    }
}

// MARK: - Activity Group

struct ActivityGroup {
    let title: String
    let activities: [Activity]
}
