module Admin
  class ChecklistItemImportsController < BaseController
    def create
      checklist = Checklist.find(params[:checklist_id])
      import = ChecklistItemCsvImport.new(checklist:, file: params[:file])

      if import.call
        redirect_to admin_checklist_path(checklist), notice: "Checklist items imported."
      else
        redirect_to admin_checklist_path(checklist), alert: import.errors.to_sentence
      end
    end
  end
end
