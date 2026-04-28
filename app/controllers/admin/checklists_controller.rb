module Admin
  class ChecklistsController < BaseController
    before_action :set_checklist, only: %i[show edit update destroy]

    def index
      @checklists = Checklist.includes(:checklist_items).order(:title)
    end

    def show
      @checklist = Checklist.includes(:checklist_items).find(params[:id])
    end

    def new
      @checklist = Checklist.new(status: :active)
    end

    def create
      @checklist = Checklist.new(checklist_params)

      if @checklist.save
        redirect_to admin_checklist_path(@checklist), notice: "Checklist created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      redirect_to admin_checklist_path(@checklist)
    end

    def update
      if @checklist.update(checklist_params)
        redirect_to admin_checklist_path(@checklist), notice: "Checklist updated."
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
      params.require(:checklist).permit(:title, :notes, :status, :start_at)
    end
  end
end
