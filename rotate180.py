# ImageJ 批量旋转180度并覆盖保存脚本
# created by deepseek

from ij import IJ, WindowManager
from ij.io import FileSaver
import os

def main():
    # 获取所有打开的图像
    images = []
    image_ids = WindowManager.getIDList()
    if image_ids:
        for img_id in image_ids:
            imp = WindowManager.getImage(img_id)
            if imp:
                images.append(imp)
    
    if not images:
        IJ.showMessage("Error", "No images opened!")
        return
    
    # 处理每张图像
    success_count = 0
    for imp in images:
        original_path = get_original_path(imp)
        if not original_path:
            continue
        
        try:
            # ==== 关键修正：使用两步旋转代替180度命令 ====
            IJ.run(imp, "Rotate 90 Degrees Right", "")
            IJ.run(imp, "Rotate 90 Degrees Right", "")
            
            # ==== 静默保存方法 ====
            if save_silently(imp, original_path):
                success_count += 1
                IJ.log("Saved: " + original_path)
            else:
                IJ.log("Save failed: " + original_path)
                
            # 清理资源
            imp.changes = False
            imp.close()
            
        except Exception as e:
            IJ.log("Error: " + str(e))
    
    # 结果提示
    IJ.showMessage("Complete", "Processed %d images" % success_count)

def get_original_path(imp):
    """获取图像原始路径 (仅ASCII路径)"""
    file_info = imp.getOriginalFileInfo()
    if not file_info or not file_info.directory or not file_info.fileName:
        return None
    return os.path.join(file_info.directory, file_info.fileName)

def save_silently(imp, path):
    """静默保存方法 (无对话框)"""
    try:
        ext = os.path.splitext(path)[1].lower()
        
        # ==== 关键修正：直接调用保存接口 ====
        if ext in [".tif", ".tiff"]:
            return FileSaver(imp).saveAsTiff(path)
        elif ext in [".jpg", ".jpeg"]:
            return FileSaver(imp).saveAsJpeg(path)
        else:
            IJ.log("Unsupported format: " + path)
            return False
    except Exception as e:
        IJ.log("Save error: " + str(e))
        return False

if __name__ == "__main__":
    main()