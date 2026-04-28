module Admin
  class ChecklistItemsController < BaseController
    before_action :set_checklist
    before_action :set_checklist_item, only: %i[edit update destroy]

    def new
      @checklist_item = @checklist.checklist_items.new
    end

    def create
      @checklist_item = @checklist.checklist_items.new(checklist_item_params)

      if @checklist_item.save
        redirect_to admin_checklist_path(@checklist), notice: "Checklist item created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @checklist_item.update(checklist_item_params)
        redirect_to admin_checklist_path(@checklist), notice: "Checklist item updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @checklist_item.destroy
      redirect_to admin_checklist_path(@checklist), notice: "Checklist item deleted."
    end

    private

    def set_checklist
      @checklist = Checklist.find(params[:checklist_id])
    end

    def set_checklist_item
      @checklist_item = @checklist.checklist_items.find(params[:id])
    end

    def checklist_item_params
      params.require(:checklist_item).permit(:item_text, :sort_order, :desired_completion_offset_minutes)
    end
  end
end
