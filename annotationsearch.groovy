import qupath.lib.gui.scripting.QPEx
import qupath.lib.projects.Project

// 配置参数：要查找的注释分类名称（区分大小写）
def targetAnnotationClass = "PL"

// 获取当前项目
def project = QPEx.getProject()
def matchedImages = []

project.getImageList().eachWithIndex { entry, index ->
    try {
        // 加载图像数据
        def imageData = entry.readImageData()
        def hierarchy = imageData.getHierarchy()
        
        // 获取所有注释对象
        def annotations = hierarchy.getAnnotationObjects()
        
        // 检查是否存在目标分类注释
        def hasTarget = annotations.any { ann ->
            ann.getPathClass()?.getName() == targetAnnotationClass
        }
        
        if (hasTarget) {
            matchedImages << entry.getImageName()
            print "✅ [${index+1}/${project.getImageList().size()}] ${entry.getImageName()} 包含 '${targetAnnotationClass}' 注释"
        } else {
            print "⭕ [${index+1}/${project.getImageList().size()}] ${entry.getImageName()} 无目标注释"
        }
        
    } catch (Exception e) {
        print "⚠️ [${index+1}/${project.getImageList().size()}] ${entry.getImageName()} 检查失败：${e.getMessage().take(50)}..."
    }
}

// 输出最终结果
print "\n===== 扫描完成 ====="
print "项目中共 ${project.getImageList().size()} 张图像"
print "包含 '${targetAnnotationClass}' 注释的图像："
matchedImages.eachWithIndex { name, idx ->
    print "  ${idx+1}. ${name}"
}
print "总计：${matchedImages.size()} 张"
