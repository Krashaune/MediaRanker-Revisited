require 'test_helper'

describe WorksController do
  describe "root" do
    it "succeeds with all media types" do
      # Precondition: there is at least one media of each category

      # Assumptions
      Work.best_albums.count.must_be :>, 0
      Work.best_books.count.must_be :>, 0
      Work.best_movies.count.must_be :>, 0

      # Act
      get root_path

      # Assert
      must_respond_with :success
    end

    it "succeeds with one media type absent" do
      # Precondition: there is at least one media in two of the categories
      # Assumptions
      Work.best_movies.destroy_all
      Work.best_albums.count.must_be :>, 0
      Work.best_books.count.must_be :>, 0

      # Act
      get root_path

      # Assert
      must_respond_with :success

    end

    it "succeeds with no media" do
      # Assumptions
      Work.best_albums.destroy_all
      Work.best_books.destroy_all
      Work.best_movies.destroy_all

      # Act
      get root_path

      # Assert
      must_respond_with :success
    end
  end

  CATEGORIES = %w(albums books movies)
  INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]

  describe "index" do
    it "succeeds when there are works" do

      # Assumptions
      Work.count.must_be :>, 0

      #Act
      get works_path

      #Assert
      must_respond_with :success

    end

    it "succeeds when there are no works" do

      # Assumptions
      Work.destroy_all

      #Act
      get works_path

      # Assert
      must_respond_with :success
    end
  end

  describe "new" do
    it "succeeds" do

      # Act
      get new_work_path
      # Assert
      must_respond_with :success
    end
  end

  describe "create" do
    it "creates a work with valid data for a real category" do
      # Arrange
      work_data = {
        title:  'new movie',
        category: 'movie'

      }
      previous_count = Work.count

      # Assumptions
      Work.new(work_data).must_be :valid?

      # Act
      post works_path, params: { work: work_data }

      # Assert
      must_respond_with :redirect
      # must_redirect_to works_path

      Work.count.must_equal previous_count + 1
      Work.last.title.must_equal work_data[:title]


    end

    it "renders bad_request and does not update the DB for bogus data" do
      # Arrange
      work_data = {
        category: 'movie'
      }
      previous_count = Work.count

      # Assumptions
      Work.new(work_data).wont_be :valid?

      # Act
      post works_path, params: { work: work_data }

      # Assert
      must_respond_with :bad_request
      Work.count.must_equal previous_count
    end

    it "renders 400 bad_request for bogus categories" do
      # Arrange
      work_data = {
        category: 'film'
      }
      previous_count = Work.count

      # Assumptions
      Work.new(work_data).wont_be :valid?

      # Act
      post works_path, params: { work: work_data }

      # Assert
      must_respond_with :bad_request
      Work.count.must_equal previous_count
    end

  end

  describe "show" do
    it "succeeds for an extant work ID" do
      # Act
      get work_path(Work.first)

      # Assert
      must_respond_with :success
    end

    it "renders 404 not_found for a bogus work ID" do
      # Arrange
      work_id = Work.last.id + 1

      # Act
      get work_path(work_id)

      # Assert
      must_respond_with :not_found
    end
  end

  describe "edit" do
    it "succeeds for an extant work ID" do
      # Act
      get edit_work_path(Work.first)

      # Assert
      must_respond_with :success
    end

    it "renders 404 not_found for a bogus work ID" do
      # Arrange
      work_id = Work.last.id + 1

      # Act
      get edit_work_path(work_id)

      # Assert
      must_respond_with :not_found
    end
  end

  describe "update" do
    it "succeeds for valid data and an extant work ID" do
      # Arrange
      work = Work.first
      work_data = work.attributes
      work_data[:title] = "new test title"

      # Assumptions
      work.assign_attributes(work_data)
      work.must_be :valid?

      # Act
      patch work_path(work), params: { work: work_data }

      # Assert
      must_redirect_to work_path(work)
      must_respond_with :redirect

      work.reload
      work.title.must_equal work_data[:title]

    end

    it "renders bad_request for bogus data" do
      # Arrange
      work = Work.first
      work_data = work.attributes
      work_data[:title] = nil

      # Assumptions
      work.assign_attributes(work_data)
      work.wont_be :valid?

      # Act
      patch work_path(work), params: { work: work_data }

      # Assert
      # must_redirect_to work_path(work)
      must_respond_with :bad_request

      work.reload

    end

    it "renders 404 not_found for a bogus work ID" do
      work_id = Work.last.id + 1

      patch work_path(work_id)

      must_respond_with :not_found
    end
  end

  describe "destroy" do
    it "succeeds for an extant work ID" do
      work_id = Work.last.id
      previous_count = Work.count

      delete work_path(work_id)

      must_respond_with :redirect
      Work.count.must_equal previous_count - 1

      Work.find_by(id: work_id).must_be_nil
    end

    it "renders 404 not_found and does not update the DB for a bogus work ID" do
      work_id = Work.last.id + 1
      previous_count = Work.count

      delete work_path(work_id)

      must_respond_with :not_found
      Work.count.must_equal previous_count
    end
  end

  describe "upvote" do

    it "redirects to the work page if no user is logged in" do

      id = Work.first.id

      # Act
      post upvote_path(id)

      # Assert
      must_respond_with :redirect
      must_redirect_to  work_path
    end

    it "redirects to the work page after the user has logged out" do
      # Arrange
      user = User.first
      post login_url
      work = Work.first

      # Act

      post logout_path(user.id)
      post upvote_path(work.id)

      # Assert
      must_respond_with :redirect
      must_redirect_to work_path

    end

    it "succeeds for a logged-in user and a fresh user-vote pair" do
      # Arrange
      user = User.first
      post login_url
      work = Work.first

      # Act
      post upvote_path(work.id)

      # Assert
      must_respond_with :redirect
      must_redirect_to work_path(work.id)
    end

    it "redirects to the work page if the user has already voted for that work" do
      # Arrange
      user = users(:dan)
      post login_url
      work = works(:album)

      # Act
      post upvote_path(work.id)
      post upvote_path(work.id)

      # Assert
      must_respond_with :redirect
      must_redirect_to work_path(work.id)
    end
  end
end
