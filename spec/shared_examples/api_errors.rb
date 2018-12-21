shared_examples 'a client request that handles errors' do
  context 'when the resource is not found' do
    let(:interactions) do
      super().tap do |inter|
        inter[0][:response][:status] = 404
      end
    end

    it 'raises a not found error' do
      expect { subject }.to raise_error(Txbr::BrazeNotFoundError)
    end
  end

  context 'when the request is unauthorized' do
    let(:interactions) do
      super().tap do |inter|
        inter.unshift(
          request: inter[0][:request],
          response: { status: 401 }
        )
      end
    end

    it 'raises an unauthorized error' do
      expect { subject }.to raise_error(Txbr::BrazeUnauthorizedError)
    end
  end

  context 'when some other bad thing happens' do
    let(:interactions) do
      super().tap do |inter|
        inter[0][:response][:status] = 500
      end
    end

    it 'raises a generic error' do
      expect { subject }.to raise_error(Txbr::BrazeApiError)
    end
  end
end
