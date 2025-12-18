//
//  AboutBill.swift
//  Bill App
//
//  Created by 陳芸萱 on 2025/11/29.
//

//
//  ContentView.swift
//  AboutMe
//
//  Created by 林嘉誠 on 2025/9/26.
//

import SwiftUI
import MapKit

struct AboutBill: View {
    let name = "Bill"
    let age = 28
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // 背景放最底層
            Background()
            // 標題與右下角文字放在最上層
            Title()
                .offset(x: 40)
            Bottom()
            
            // 內容捲動區放中間
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 學歷標題列
                    HStack {
                        Image(systemName: "studentdesk")
                            .symbolEffect(.variableColor)
                            .font(.largeTitle)
                            .bold()
                            .padding(.trailing, 4)
                        Text("Education")
                            .font(.largeTitle)
                            .bold()
                            .padding(10)
                            .glassEffect(.regular.tint(.green.opacity(0.4)))
                    }
                    .padding(.horizontal)
                    
                    // 水平卡片列（Education）
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            EducationView(
                                collage: "National Taiwan University",
                                department: "Institute of Applied Mechanics",
                                degree: "PhD of Science",
                                start: "2023",
                                end: "present",
                                gpa: 4.25,
                                tgpa: 4.30,
                                medal: """
                                    National Taiwan University Diligence 
                                    Scholarships for Doctoral Students
                                    """,
                                logo: Image("ntu")
                            )
                            .frame(width: 350, alignment: .leading)
                            
                            EducationView(
                                collage: "National Taiwan University",
                                department: "Institute of Applied Mechanics",
                                degree: "Master of Science",
                                start: "2020",
                                end: "2022",
                                gpa: 4.08,
                                tgpa: 4.30,
                                medal: """
                                    Best Poster Award in 2022 Poster 
                                    Session of Master Thesis
                                    """,
                                logo: Image("ntu")
                            )
                            .frame(width: 350, alignment: .leading)
                            
                            EducationView(
                                collage: "Taipei Medical University",
                                department: "BioMedical Engineering",
                                degree: "Bachelor of Science",
                                start: "2016",
                                end: "2020",
                                gpa: 3.94,
                                tgpa: 4.00,
                                medal: """
                                    First Prize in 2020 Publication 
                                    of Research Contest
                                    """,
                                logo: Image("tmu")
                            )
                            .frame(width: 350, alignment: .leading)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8) // 視覺上留點上邊距即可
                    }
                    
                    // 經歷標題列
                    HStack(spacing: 4) {
                        Image(systemName: "bag.fill.badge.plus")
                            .symbolEffect(.variableColor)
                            .font(.largeTitle)
                            .bold()
                            .padding(.trailing, 4)
                        Text("Experience")
                            .font(.largeTitle)
                            .bold()
                            .padding(10)
                            .glassEffect(.regular.tint(.brown.opacity(0.4)))
                    }
                    .padding(.horizontal)
                    
                    // 水平卡片列（Work）
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            Work(
                                logo: Image("brain"),
                                position: "Research Assistant",
                                department: "Taiwan Brain Disease Foundation",
                                company: "Shuang Ho Hospital",
                                start: "2022",
                                end: "2023",
                                work1:"Registered an oral presentation at an international conference, Biosensors 2023.",
                                work2:"Collaborate with neurosurgeons about the anticoagulant dosage in cardiovascular stents."
                            )
                            
                            Work(
                                logo: Image("ntu"),
                                position: "Teaching Assistant",
                                department: "Experiments on Applied Mechanics",
                                company: "National Taiwan University",
                                start: "2025",
                                end: "Present",
                                work1: "Oversaw 5 biomedical experiments and 4 fluid mechanics experiments.",
                                work2: "Prepared experimental equipment and tools weekly, checked student’s reports, and prepared exams."
                            )
                            
                            Work(
                                logo: Image("ntu"),
                                position: "Teaching Assistant",
                                department: "English Writing for Academic Purposes",
                                company: "National Taiwan University",
                                start: "2024",
                                end: "Present",
                                work1: "Assisted group discussion on class, and marked assignments and exams",
                                work2: "Guided presentation part about 3MT, including body language, oral delivery, and other presentation skill."
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    } // <- 正確關閉 Work 的水平 ScrollView
                    
                    // Leadership 標題列（靠左）
                    HStack(spacing: 4) {
                        Image(systemName: "person.3.fill")
                            .symbolEffect(.variableColor)
                            .font(.largeTitle)
                            .bold()
                            .padding(.trailing, 4)
                        Text("Leadership")
                            .font(.largeTitle)
                            .bold()
                            .padding(10)
                            .glassEffect(.regular.tint(.yellow.opacity(0.4)))
                    }
                    // 想更貼左可改為 .padding(.leading)
                    .padding(.horizontal)
                    
                    // 水平卡片列（Leadership 也用 Work 卡片示意）
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            Leadership(
                                logo: Image("besa"),
                                position: "Minister of Public Relations Department",
                                department: "Bio Entrepreneurship Student Association",
                                company: "National Taiwan University",
                                start: "2020",
                                end: "2021",
                                work1:"Increased the number of business partners and lecturers to 40+ and 120+ respectively.",
                                work2:"Directly trained 10 members to host 20+ Public Relation Events."
                            )
                            Leadership(
                                logo: Image("debate"),
                                position: "Vice President",
                                department: "Debate Club",
                                company: "Taipei Medical University",
                                start: "2017",
                                end: "2019",
                                work1:"Established the debate club with a classmate, from zero to one, and keep guiding the members to attend more debate competitions.",
                                work2:"Participated in 5+ Debate Competition and won the Champion of a debate competition in 13 teams."
                            )
                            Leadership(
                                logo: Image("bme"),
                                position: "President",
                                department: "BioMedical Engineering Student Association",
                                company: "Taipei Medical University",
                                start: "2017",
                                end: "2018",
                                work1:"Established the Student Association with the first session students.",
                                work2:"Hosted 10+ student events, such as medical engineering camps, medical engineering creative competitions, and the orientation camp."
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "microphone.circle.fill")
                            .symbolEffect(.variableColor)
                            .font(.largeTitle)
                            .bold()
                            .padding(.trailing, 4)
                        Text("Conference")
                            .font(.largeTitle)
                            .bold()
                            .padding(10)
                            .glassEffect(.regular.tint(.orange.opacity(0.4)))
                    }
                    // 想更貼左可改為 .padding(.leading)
                    .padding(.horizontal)
                    Travel()
                    
                    
                    HStack(spacing: 4) {
                        Image(systemName: "info.square.fill")
                            .symbolEffect(.variableColor)
                            .font(.largeTitle)
                            .bold()
                            .padding(.trailing, 4)
                        Text("Information")
                            .font(.largeTitle)
                            .bold()
                            .padding(10)
                            .glassEffect(.regular.tint(.blue.opacity(0.4)))
                    }
                    // 想更貼左可改為 .padding(.leading)
                    .padding(.horizontal)
                    
                    HStack(spacing: 4) {
                        NameCard()
                            .padding(.horizontal)
                        
                        // 將 LinkedIn 圖片用 mask 裁成自訂形狀，並提供可點擊的連結
                        VStack {
                            Image("linkedin")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .mask {
                                    // 遮罩視圖：不透明處保留，透明處裁掉
                                    Image(systemName: "arrowshape.down.fill")
                                        .font(.system(size: 70, weight: .black, design: .rounded))
                                        .frame(width: 80, height: 80, alignment: .center)
                                }
                            
                            // 只讓「LinkedIn」文字可點開連結
                            Link("LinkedIn",
                                 destination: URL(string: "https://www.linkedin.com/in/jia-cheng-lin-68b2751a7/")!
                            )
                            .font(.system(size: 26, weight: .bold))
                            
                            Text("[Instagram](https://www.instagram.com/bill092801/)")
                                .font(.custom("MateSC-Regular", size: 24))
                                .tint(.red)
                            Image("instagram")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .mask {
                                    // 遮罩視圖：不透明處保留，透明處裁掉
                                    Image(systemName: "arrowshape.up.fill")
                                        .font(.system(size: 70, weight: .black, design: .rounded))
                                        .frame(width: 80, height: 80, alignment: .center)
                                }
                        }
                    }
                }
                // 用 padding 讓出上下空間，避免被 Title/Bottom 蓋住
                .padding(.top, 120)   // 推開上方 Title 的空間，可依實際字體高度微調
                .padding(.bottom, 80) // 預留右下角 Bottom 的空間
            }
            
//            // 標題與右下角文字放在最上層
//            Title()
//            Bottom()
        }  // 第一個 ZStack
    } // body
} // struct


#Preview {
    AboutBill()
}
