//
//  ViewController.swift
//  FileManager-PhotoPicker-Domo
//
//  Created by JINSEOK on 2023/05/17.
//

import UIKit
import PhotosUI
import SnapKit

class ViewController: UIViewController {
    
    // Identifier와 PHPickerResult로 만든 Dictionary
    private var selections = [String : PHPickerResult]()
    // 선택한 사진의 순서에 맞게 배열로 Identifier들을 저장해줄 겁니다. (딕셔너리는 순서가 없기 때문에)
    private var selectedAssetIdentifiers = [String]()
    
    lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.spacing = 10
        stack.axis = .vertical
        stack.distribution = .equalCentering
        return stack
    }()
    
    lazy var button: UIButton = {
        let button = UIButton(frame: CGRect(x: (view.frame.width/2)-50, y: 670, width: 100, height: 60))
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 20
        button.setTitle("PHPicker", for: .normal)
        return button
    }()
    
    lazy var saveButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 30, y: 740, width: 100, height: 60))
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 20
        button.setTitle("Save", for: .normal)
        return button
    }()
    
    lazy var readButton: UIButton = {
        let button = UIButton(frame: CGRect(x: (view.frame.width/2)-50, y: 740, width: 100, height: 60))
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 20
        button.setTitle("Read", for: .normal)
        return button
    }()
    
    lazy var deleteButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 260, y: 740, width: 100, height: 60))
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 20
        button.setTitle("Delete", for: .normal)
        return button
    }()
    

    var identifier = UUID()
    var images = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(stackView)
        
        let buttons = [button, saveButton, readButton, deleteButton]
        buttons.forEach { self.view.addSubview($0) }
        
        
        stackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(self.view.safeAreaLayoutGuide).offset(20)
            $0.bottom.equalTo(self.button.snp.top).offset(-20)
        }
        
        button.addTarget(self, action: #selector(photoButtonHandler), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
        readButton.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)


    }
    
    @objc func photoButtonHandler(_ sender: UIButton) {
        presentPicker()
    }
    
    @objc func buttonHandler(_ sender: UIButton) {
    
        switch sender.currentTitle {
        case "Save":
            saveImageToDirectory(identifier: "\(identifier)", image: images.first!)
        case "Read":
            guard let image = loadImageFromDirectory(idnetifier: "27261A38-E370-499F-9687-B82BFBE4E7F9") else { return }
            addImage(image)
        case "Delete":
            replaceImageFromDirectoryV2(at: "E4096C21-0006-4760-AC05-2C50D4C3C039", with: "\(identifier)")
        default: break
        }
    }

    // MARK: - 이미지 저장
    
    func saveImageToDirectory(identifier: String, image: UIImage) {
        // 저장할 디렉토리 경로 설정 (picturesDirectory도 존재하지만 Realm과 같은 경로에 저장하기 위해서 documentDirectory 사용함.)
        // userDomainMask: 사용자 홈 디렉토리는 사용자 관련 파일이 저장되는 곳입니다.
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first!
        // Realm에서 이미지에 사용될 이름인 identifier를 저장 후, 사용하면 됩니다
        let imageName = "\(identifier)"
        // 이미지의 경로 및 확장자 형식 (conformingTo: 확장자)
        let fileURL = documentsDirectory.appendingPathComponent(imageName, conformingTo: .jpeg)
        
        do {
            // 파일로 저장하기 위해선 data 타입으로 변환이 필요합니다. (JPEG은 압축을 해주므로 크기가 줄어듭니다. PNG는 비손실)
            if let imageData = image.jpegData(compressionQuality: 1) {
                // 이미지 데이터를 fileURL의 경로에 저장시킵니다.
                try imageData.write(to: fileURL)
                print("Image saved at: \(fileURL)")
            }
            
        } catch {
            print("Failed to save images: \(error)")
        }
    }
    
    // MARK: - 이미지들 저장
    // 여러 사진들을 받기 위해서 만듬
    func saveImagesToDirectory(identifier: String, images: [UIImage]) {
        let fileManager = FileManager.default
        
        // 저장할 디렉토리 경로 설정 (picturesDirectory도 존재하지만 Realm과 같은 경로에 저장하기 위해서 documentDirectory 사용함.)
        // userDomainMask: 사용자 홈 디렉토리는 사용자 관련 파일이 저장되는 곳입니다.
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        // 식별자 폴더를 관리하기 위해 images란 폴더를 만들어 줬습니다. (images folder -> 식별자 folder -> 이미지들)
        let imagesFolderDirectory = documentsDirectory.appendingPathComponent("images")
        // 식별자 폴더로 이미지들이 저장될 폴더입니다. (== imageURL)
        let imageDirectory = imagesFolderDirectory.appendingPathComponent("\(identifier)")
        
        do {
            // 이미지 폴더 디렉토리가 없다면 생성
            if !fileManager.fileExists(atPath: imagesFolderDirectory.path) {
                try fileManager.createDirectory(at: imagesFolderDirectory, withIntermediateDirectories: true)
            }
            if !fileManager.fileExists(atPath: imageDirectory.path) {
                try fileManager.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
            }
            // 이미지 파일을 저장
            for (index, image) in images.enumerated() {
                let fileName = "\(index)"
                let fileURL = imageDirectory.appendingPathComponent(fileName, conformingTo: .jpeg)
                
                if let imageData = image.jpegData(compressionQuality: 1.0) {
                    try imageData.write(to: fileURL)
                    print("Image saved at: \(fileURL)")
                }
            }
        } catch {
            print("Failed to save images: \(error)")
        }
    }

    
    // MARK: - 이미지 로드
    
    // 이미지 저장 방법과 비슷합니다
    func loadImageFromDirectory(idnetifier: String) -> UIImage? {
        let fileManager = FileManager.default
        // 파일 경로로 접근
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(idnetifier, conformingTo: .jpeg)
        
        // 이미지 파일이 존재한다면, 이미지로 변환 후 리턴
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    
    // MARK: - 이미지 삭제

    func deleteImageFromDirectory(idnetifier: String) {
        let fileManager = FileManager.default
        let documuentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documuentDirectory.appendingPathComponent(idnetifier, conformingTo: .jpeg)
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("Successfully deleted image")
        } catch {
            print("Failed to delete image: \(error)")
        }
    }
    
    
    // MARK: - 이미지 교체

    func replaceImageFromDirectory(at oldIdentifier: String, with newIdentifier: String) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let oldFileURL = documentsDirectory.appendingPathComponent(oldIdentifier, conformingTo: .jpeg)
        let newFileURL = documentsDirectory.appendingPathComponent(newIdentifier, conformingTo: .jpeg)

        do {
            try fileManager.replaceItem(at: oldFileURL, withItemAt: newFileURL, backupItemName: nil, resultingItemURL: nil)
            print("Successfully replace image")

        } catch {
            print("Failed to replace image: \(error)")
        }
    }
    
    // 이미지 교체 V.2
    
    func replaceImageFromDirectoryV2(at oldIdentifier: String, with newIdentifier: String) {
        deleteImageFromDirectory(idnetifier: oldIdentifier)
        saveImageToDirectory(identifier: newIdentifier, image: images.first!)
    }
    
    // MARK: - 포토 피커 설정들

    private func presentPicker() {
        // 이미지의 Identifier를 사용하기 위해서는 초기화를 shared로 해줘야 합니다.
        var config = PHPickerConfiguration(photoLibrary: .shared())
        // 라이브러리에서 보여줄 Assets을 필터를 한다. (기본값: 이미지, 비디오, 라이브포토)
        config.filter = PHPickerFilter.any(of: [.images])
        // 다중 선택 갯수 설정 (0 = 무제한)
        config.selectionLimit = 1
        // 선택 동작을 나타냄 (default: 기본 틱 모양, ordered: 선택한 순서대로 숫자로 표현, people: 뭔지 모르겠게요)
        config.selection = .ordered
        // 잘은 모르겠지만, current로 설정하면 트랜스 코딩을 방지한다고 하네요!?
        config.preferredAssetRepresentationMode = .current
        // 이 동작이 있어야 Picker를 실행 시, 선택했던 이미지를 기억해 표시할 수 있다. (델리게이트 코드 참고)
        config.preselectedAssetIdentifiers = selectedAssetIdentifiers
        
        // 만든 Configuration를 사용해 PHPicker 컨트롤러 객체 생성
        let imagePicker = PHPickerViewController(configuration: config)
        imagePicker.delegate = self
        
        self.present(imagePicker, animated: true)
    }
    
    
    private func displayImage() {
        // 처음 스택뷰의 서브뷰들을 모두 제거함
        self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let dispatchGroup = DispatchGroup()
        // identifier와 이미지로 dictionary를 만듬 (selectedAssetIdentifiers의 순서에 따라 이미지를 받을 예정입니다.)
        var imagesDict = [String: UIImage]()

        for (identifier, result) in selections {
            
            dispatchGroup.enter()
                        
            let itemProvider = result.itemProvider
            // 만약 itemProvider에서 UIImage로 로드가 가능하다면?
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                // 로드 핸들러를 통해 UIImage를 처리해 줍시다. (비동기적으로 동작)
                itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    
                    guard let image = image as? UIImage else { return }
                    
                    imagesDict[identifier] = image
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            
            guard let self = self else { return }
            
            self.images = []
            self.identifier = UUID()
            
            for identifier in self.selectedAssetIdentifiers {
                guard let image = imagesDict[identifier] else { return }
//                self.addImage(image)
                
                self.images.append(image)
            }
        }
    }
    
    
    private func addImage(_ image: UIImage) {
        
        let imageView = UIImageView()
        imageView.image = image
        
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(180)
        }
        
        self.stackView.addArrangedSubview(imageView)
    }
}



extension ViewController : PHPickerViewControllerDelegate {
    // picker가 종료되면 동작 합니다.
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        // picker가 선택이 완료되면 화면 내리기
        picker.dismiss(animated: true)
        
        // Picker의 작업이 끝난 후, 새로 만들어질 selections을 담을 변수를 생성
        var newSelections = [String: PHPickerResult]()
        
        for result in results {
            let identifier = result.assetIdentifier!
            // ⭐️ 여기는 WWDC에서 3분 부분을 참고하세요. (Picker의 사진의 저장 방식)
            newSelections[identifier] = selections[identifier] ?? result
        }
        
        // selections에 새로 만들어진 newSelection을 넣어줍시다.
        selections = newSelections
        // Picker에서 선택한 이미지의 Identifier들을 저장 (assetIdentifier은 옵셔널 값이라서 compactMap 받음)
        // 위의 PHPickerConfiguration에서 사용하기 위해서 입니다.
        selectedAssetIdentifiers = results.compactMap { $0.assetIdentifier }
        
        // 👉 만약 비어있다면 스택뷰 초기화, selection이 하나라도 있다면 displayImage 실행
        if selections.isEmpty {
            stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        } else {
            displayImage()
        }
    }
}
//PNG -> 비손실 그래픽 파일 포맷
//
//JPEG -> 이미지 압축시킬 때 일부 데이터를 날려버리는 손실 압축 기법 표준.





