import SwiftUI

// StatsCard is now replaced by QuickStatItem in ProfileView.swift
// Keeping this file for any legacy references

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(GolfrColors.primary.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(GolfrColors.primary)
            }

            Text(value)
                .font(GolfrFonts.title3())
                .foregroundColor(GolfrColors.textPrimary)

            Text(title)
                .font(GolfrFonts.caption())
                .foregroundColor(GolfrColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .golfrCard(cornerRadius: 14)
    }
}
