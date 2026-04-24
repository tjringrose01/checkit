module Admin
  class ChecklistsController < BaseController
    before_action :set_checklist, only: %i[edit update destroy]

    def index
      @checklists = Checklist.includes(:checklist_items).order(:title)
    end

    def new
      @checklist = Checklist.new(status: :active)
    end

    def create
      @checklist = Checklist.new(checklist_params)

      if @checklist.save
        redirect_to admin_checklists_path, notice: "Checklist created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @checklist.update(checklist_params)
        redirect_to admin_checklists_path, notice: "Checklist updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @checklist.destroy
      redirect_to admin_checklists_path, notice: "Checklist deleted."
    end

    private

    def set_checklist
      @checklist = Checklist.find(params[:id])
    end

    def checklist_params
      params.require(:checklist).permit(:title, :notes, :status)
    end
  end
end
