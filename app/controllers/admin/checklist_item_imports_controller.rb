module Admin
  class ChecklistItemImportsController < BaseController
    def create
      checklist = Checklist.find(params[:checklist_id])
      import = ChecklistItemCsvImport.new(checklist:, file: params[:file])

      if import.call
        redirect_to admin_checklists_path, notice: "Checklist items imported."
      else
        redirect_to admin_checklists_path, alert: import.errors.to_sentence
      end
    end
  end
end
