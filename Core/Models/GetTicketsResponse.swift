//
//  GetTicketsBody.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 28.01.2025.
//


struct GetTicketsResponse: Decodable {
    let page: Page
    let statistic: Statistic
}

extension GetTicketsResponse {
    struct Page: Decodable {
        let totalPages: Int
        let totalElements: Int
        let size: Int
        let content: [Ticket]
        let number: Int
        let sort: Sort
        let numberOfElements: Int
        let pageable: Pageable
        let first: Bool
        let last: Bool
        let empty: Bool
    }

    struct Ticket: Decodable {
        let ticketId: String
        let nomenclatureId: String
        let nomenclature: String
        let title: String
        let isOutcome: Bool
        let date: Int
        let financialImpact: String
        let creator: Creator
        let downloadUrl: String?
        let contentType: String?
        let isVerified: Bool
    }

    struct Creator: Decodable {
        let userId: String
        let name: String
        let surname: String
        let isEmployee: Bool
        let patronymic: String?
        let imageUrl: String?
        let jobTitle: String?
    }

    struct Statistic: Decodable {
        let incomes: String
        let outcomes: String
        let delta: String
    }

    struct Sort: Decodable {
        let empty: Bool
        let sorted: Bool
        let unsorted: Bool
    }

    struct Pageable: Decodable {
        let pageNumber: Int
        let pageSize: Int
        let offset: Int
        let paged: Bool
        let unpaged: Bool
    }
}
